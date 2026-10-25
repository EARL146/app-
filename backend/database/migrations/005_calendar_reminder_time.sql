-- Apply after 003_app_workflows.sql to let customers choose a reminder time.
-- Existing reminders default to 9:00 AM local time.
ALTER TABLE user_calendar_reminders
    ADD COLUMN reminder_time TIME NOT NULL DEFAULT '09:00:00' AFTER reminder_date;
