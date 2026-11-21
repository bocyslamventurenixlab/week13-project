from pathlib import Path

from openpyxl import Workbook

from ingestion.excel_import import read_workbook


def _save_workbook(path: Path, headers: list[str], rows: list[list[object]]) -> None:
    workbook = Workbook()
    worksheet = workbook.active
    worksheet.append(headers)
    for row in rows:
        worksheet.append(row)
    workbook.save(path)


def test_reads_supported_fields_and_normalizes_blank_values(tmp_path):
    path = tmp_path / "clients.xlsx"
    _save_workbook(
        path,
        [
            "Client Name",
            "Age",
            "Cognitive Level",
            "Diet",
            "Supplement",
            "Restraints",
            "Activity Group",
        ],
        [
            [" Synthetic Client ", 80.0, "Level A", "Diet A", None, "None", "Group A"],
            [None, None, None, None, None, None, None],
        ],
    )

    result = read_workbook(path)

    assert result.can_import
    assert [client.model_dump() for client in result.clients] == [
        {
            "full_name": "Synthetic Client",
            "age_years": 80,
            "cognitive_level": "Level A",
            "diet": "Diet A",
            "supplements": None,
            "restraints": "None",
            "activity_group": "Group A",
        }
    ]


def test_reports_invalid_rows_and_unmapped_columns(tmp_path):
    path = tmp_path / "invalid.xlsx"
    _save_workbook(
        path,
        ["Name", "Age", "Unmapped Detail"],
        [
            ["Synthetic Client", "unknown", "example"],
            ["Synthetic Client B", -1, "example"],
        ],
    )

    result = read_workbook(path)

    assert not result.can_import
    assert result.clients == []
    assert {issue.column for issue in result.issues} == {
        "Unmapped Detail",
        "age_years",
    }


def test_rejects_duplicate_headers(tmp_path):
    path = tmp_path / "ambiguous.xlsx"
    _save_workbook(
        path,
        ["Name", "Client Name", "Age"],
        [["Synthetic Client", "Other Name", 80]],
    )

    result = read_workbook(path)

    assert not result.can_import
    assert any("Multiple columns map to full_name" in issue.message for issue in result.issues)


def test_rejects_missing_name_column(tmp_path):
    path = tmp_path / "missing-name.xlsx"
    _save_workbook(path, ["Age"], [[80]])

    result = read_workbook(path)

    assert not result.can_import
    assert any("A name column is required" in issue.message for issue in result.issues)


def test_rejects_formula_values_instead_of_importing_cached_or_unverified_data(tmp_path):
    path = tmp_path / "formula.xlsx"
    workbook = Workbook()
    worksheet = workbook.active
    worksheet.append(["Name", "Age"])
    worksheet.append(["Synthetic Client", "=40+40"])
    workbook.save(path)

    result = read_workbook(path)

    assert not result.can_import
    assert any("Formula-based values are not supported" in issue.message for issue in result.issues)
