export interface MatchEvent {
  uid: string;
  title: string;
  startTime: number;   // ms timestamp (local time)
  endTime: number;     // ms timestamp (local time)
  location: string;
  description: string;
  status: 'finished' | 'scheduled';
  reminderMinutes: number;
}
