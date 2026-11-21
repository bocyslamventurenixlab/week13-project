from pathlib import Path
import re
from zipfile import BadZipFile

from openpyxl import load_workbook
from openpyxl.utils.exceptions import InvalidFileException
from openpyxl.workbook.workbook import Workbook
from pydantic import ValidationError

from ingestion.validation import (
    ClientImportRow,
    ImportIssue,
    WorkbookImportResult,
)


class WorkbookReadError(ValueError):
    pass


HEADER_ALIASES = {
    "full_name": {"name", "fullname", "clientname"},
    "age_years": {"age", "ageyears"},
    "cognitive_level": {"cognitivelevel"},
    "diet": {"diet"},
    "supplements": {"supplement", "supplements"},
    "restraints": {"restraint", "restraints"},
    "activity_group": {"activitygroup", "activitiesgroup"},
}


def _normalize_header(value: object) -> str:
    return re.sub(r"[^a-z0-9]", "", str(value).casefold())


def _is_blank(value: object) -> bool:
    return value is None or (isinstance(value, str) and not value.strip())


def read_workbook(path: str | Path) -> WorkbookImportResult:
    workbook_path = Path(path)
    if workbook_path.suffix.casefold() not in {".xlsx", ".xlsm"}:
        raise WorkbookReadError("Only .xlsx and .xlsm workbooks are supported")

    try:
        workbook = load_workbook(
            workbook_path,
            read_only=True,
            data_only=False,
            keep_links=False,
        )
    except (OSError, BadZipFile, InvalidFileException) as error:
        raise WorkbookReadError(f"Unable to read workbook: {error}") from error

    try:
        return _parse_workbook(workbook)
    finally:
        workbook.close()


def _parse_workbook(workbook: Workbook) -> WorkbookImportResult:
    clients: list[ClientImportRow] = []
    issues: list[ImportIssue] = []

    for worksheet in workbook.worksheets:
        rows = worksheet.iter_rows(values_only=False)
        header_cells = next(rows, None)
        if header_cells is None:
            issues.append(
                ImportIssue(
                    sheet_name=worksheet.title,
                    row_number=1,
                    message="Worksheet is empty",
                )
            )
            continue

        column_fields: dict[int, str] = {}
        field_columns: dict[str, int] = {}
        for column_index, cell in enumerate(header_cells):
            header_value = cell.value
            if _is_blank(header_value):
                continue
            if cell.data_type == "f":
                issues.append(
                    ImportIssue(
                        sheet_name=worksheet.title,
                        row_number=1,
                        message="Formula-based headers are not supported",
                    )
                )
                continue

            normalized_header = _normalize_header(header_value)
            field_name = next(
                (
                    candidate
                    for candidate, aliases in HEADER_ALIASES.items()
                    if normalized_header in aliases
                ),
                None,
            )
            if field_name is None:
                issues.append(
                    ImportIssue(
                        sheet_name=worksheet.title,
                        row_number=1,
                        column=str(header_value),
                        message="Unrecognized column; map it before importing",
                    )
                )
                continue
            if field_name in field_columns:
                issues.append(
                    ImportIssue(
                        sheet_name=worksheet.title,
                        row_number=1,
                        column=str(header_value),
                        message=f"Multiple columns map to {field_name}",
                    )
                )
                continue

            column_fields[column_index] = field_name
            field_columns[field_name] = column_index

        if "full_name" not in field_columns:
            issues.append(
                ImportIssue(
                    sheet_name=worksheet.title,
                    row_number=1,
                    column="full_name",
                    message="A name column is required",
                )
            )
            continue

        for row_number, cells in enumerate(rows, start=2):
            if all(_is_blank(cell.value) for cell in cells):
                continue

            row_data: dict[str, object] = {}
            for column_index, cell in enumerate(cells):
                if cell.data_type == "f":
                    issues.append(
                        ImportIssue(
                            sheet_name=worksheet.title,
                            row_number=row_number,
                            column=column_fields.get(column_index),
                            message="Formula-based values are not supported",
                        )
                    )
                    continue
                field_name = column_fields.get(column_index)
                if field_name is not None:
                    row_data[field_name] = cell.value

            try:
                clients.append(ClientImportRow.model_validate(row_data))
            except ValidationError as error:
                for detail in error.errors():
                    location = detail["loc"]
                    issues.append(
                        ImportIssue(
                            sheet_name=worksheet.title,
                            row_number=row_number,
                            column=str(location[0]) if location else None,
                            message=detail["msg"],
                        )
                    )

    return WorkbookImportResult(clients=clients, issues=issues)
