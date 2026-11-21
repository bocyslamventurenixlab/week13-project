export interface ClientRecord {
  id: string;
  fullName: string;
  ageYears: number | null;
  cognitiveLevel: string | null;
  diet: string | null;
  supplements: string | null;
  restraints: string | null;
  activityGroup: string | null;
  createdAt: string;
}

export interface ClientListResponse {
  clients: ClientRecord[];
}
