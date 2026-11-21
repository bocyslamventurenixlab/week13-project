from pydantic import BaseModel, ConfigDict, Field, field_validator


class ClientImportRow(BaseModel):
    model_config = ConfigDict(extra="forbid")

    full_name: str
    age_years: int | None = Field(default=None, ge=0)
    cognitive_level: str | None = None
    diet: str | None = None
    supplements: str | None = None
    restraints: str | None = None
    activity_group: str | None = None

    @field_validator("full_name")
    @classmethod
    def normalize_full_name(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("must not be blank")
        return normalized

    @field_validator("age_years", mode="before")
    @classmethod
    def normalize_age(cls, value: object) -> object:
        if value is None or value == "":
            return None
        if isinstance(value, bool):
            raise ValueError("must be a whole number of years")
        if isinstance(value, float):
            if not value.is_integer():
                raise ValueError("must be a whole number of years")
            return int(value)
        if isinstance(value, str):
            normalized = value.strip()
            return normalized or None
        return value

    @field_validator(
        "cognitive_level",
        "diet",
        "supplements",
        "restraints",
        "activity_group",
        mode="before",
    )
    @classmethod
    def normalize_optional_text(cls, value: object) -> object:
        if isinstance(value, str):
            return value.strip() or None
        return value


class ImportIssue(BaseModel):
    sheet_name: str
    row_number: int
    column: str | None = None
    message: str


class WorkbookImportResult(BaseModel):
    clients: list[ClientImportRow]
    issues: list[ImportIssue]

    @property
    def can_import(self) -> bool:
        return bool(self.clients) and not self.issues
