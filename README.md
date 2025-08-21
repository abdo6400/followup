📱 Final Features (with Screens)
🔑 Authentication

Static Admin account (hardcoded or from DB).

Sheikh account (created by Admin).

Parent account (self-register).

Role-based navigation (Admin → Admin Dashboard, Sheikh → Sheikh Dashboard, Parent → Parent Dashboard).

🛠️ Admin Features

Manage Categories

Create, edit, delete categories (e.g., Quran Recitation, Behavior, Memorization, etc.).

Categories act as groups that link students & Sheikhs.

Manage Sheikhs

Create Sheikh accounts.

Assign Sheikh to one or more categories.

Define Sheikh working days in the week (dynamic, e.g., Sat & Tue).

Manage Students

Add/Edit/Delete students.

Assign students to categories.

Assign students to Sheikhs (students can belong to multiple categories & multiple Sheikhs if needed).

Track which category and which Sheikh the student belongs to.

Manage Tasks

Create dynamic tasks (not static).

Tasks can belong to categories (optional).

Each task has:

Title (e.g., Memorization, Attendance, Behavior, etc.)

Points or grading type (1–10, yes/no, custom points).

View Reports

Daily/weekly reports of:

Sheikh attendance

Student attendance & task performance

Category performance

Notifications (via Firebase)

Send announcement to all parents.

Send targeted notification to a category (e.g., "Group A class canceled").

Send task result notifications automatically to parents.

👳 Sheikh Features

Dashboard

View assigned categories & students.

View schedule based on assigned working days.

Attendance

Mark attendance for each student in assigned categories.

Track which students came per day.

Tasks

Mark performance of students for each task (points, completed, etc.).

Dynamic tasks come from Admin.

Reports

See reports for their students only.

👨‍👩‍👧 Parent Features

Account

Self-register account.

Add one or more children (students).

Each child is linked to a category and a Sheikh (via Admin assignment).

Dashboard

View children & their assigned categories.

View Sheikh(s) teaching their children.

Attendance & Task Tracking

Daily/weekly attendance report of each child.

Task results (points, grades, progress).

Notifications

Receive updates from Admin (announcements).

Receive Sheikh updates (task scores, attendance).

📂 Data Structure (Firestore)

Users

{id, role: [admin, sheikh, parent], name, email, …}

Categories

{id, name, description}

Sheikhs

{id, name, assignedCategories: [], workingDays: []}

Students

{id, name, parentId, assignedCategories: [], assignedSheikhs: []}

Tasks

{id, title, type, categoryId?, maxPoints}

Attendance

{studentId, date, status}

TaskResults

{studentId, taskId, date, points}

Notifications

{title, message, target: [all/parent/category/sheikh/student]}
