# User Guides

Complete user documentation for the AWS Serverless Task Manager.

## 📋 Documentation Index

- [Admin Guide](USER_GUIDE_ADMIN.md) - For administrators and system managers
- [Member Guide](USER_GUIDE_MEMBER.md) - For project members and task users

## Quick Links by Role

### 👥 For Administrators

**User Management**:
- Creating and managing users
- Assigning roles and permissions
- Managing user groups (Admins, ProjectManagers, Members)

**Project Management**:
- Creating and archiving projects
- Managing project settings
- Assigning project managers

**System Configuration**:
- Configuring notifications
- Managing integrations
- System monitoring and health checks

**Security & Compliance**:
- Reviewing audit logs
- Managing access policies
- Security incident response

➡️ [Read the Admin Guide](USER_GUIDE_ADMIN.md)

---

### 📝 For Project Managers

**Project Leadership**:
- Managing project tasks and sprints
- Team member coordination
- Project analytics and reporting

**Task Management**:
- Creating and assigning tasks
- Tracking task progress
- Managing task prioritization

**Team Management**:
- Adding team members
- Managing permissions
- Team performance tracking

➡️ [Read the Admin Guide](USER_GUIDE_ADMIN.md) (Project Manager sections)

---

### ✅ For Team Members

**Daily Task Management**:
- Viewing assigned tasks
- Updating task status
- Adding comments and attachments

**Collaboration**:
- Task comments and discussions
- File sharing
- @mentions and notifications

**Personal Dashboard**:
- My tasks overview
- Upcoming deadlines
- Recent activity

**Notifications**:
- Email notifications
- In-app notifications
- Notification preferences

➡️ [Read the Member Guide](USER_GUIDE_MEMBER.md)

---

## Getting Started

### First Time Users

1. **Receive invitation email** from administrator
2. **Set your password** via the link in email
3. **Log in** to the application
4. **Complete your profile** (name, avatar, preferences)
5. **Explore your dashboard** and assigned tasks

### Accessing the Application

**Web Application**:
- Production: https://app.taskmanager.example.com
- Staging: https://staging.taskmanager.example.com

**Mobile Application** (coming soon):
- iOS App Store
- Google Play Store

### Login Process

1. Navigate to the application URL
2. Enter your email address
3. Enter your password
4. (Optional) MFA verification code if enabled
5. Access your dashboard

### Forgot Password

1. Click "Forgot Password" on login page
2. Enter your email address
3. Check email for reset code
4. Enter code and new password
5. Log in with new password

## Common Tasks

### For All Users

#### Update Your Profile
1. Click profile icon → Settings
2. Update your information
3. Click Save

#### Change Password
1. Go to Settings → Security
2. Click "Change Password"
3. Enter current and new password
4. Click Update

#### Set Notification Preferences
1. Go to Settings → Notifications
2. Toggle notification types
3. Choose delivery methods (email, in-app)
4. Click Save

#### Upload Avatar
1. Go to Settings → Profile
2. Click "Upload Avatar"
3. Select image file
4. Crop and adjust
5. Click Save

### For Admins

#### Create New User
```bash
# Via CLI
./scripts/create-admin.sh user@example.com

# Or via UI
Admin Panel → Users → Add User
```

#### Assign User to Group
1. Navigate to Admin Panel → Users
2. Select user
3. Click "Groups"
4. Add to group (Admins, ProjectManagers, Members)
5. Click Save

#### View System Logs
1. Navigate to Admin Panel → Logs
2. Filter by date, user, or action
3. Export logs if needed

### For Project Managers

#### Create Project
1. Click "+ New Project"
2. Enter project details
3. Add team members
4. Set project deadline
5. Click Create

#### Create Sprint
1. Open project
2. Click "Sprints" → "New Sprint"
3. Set sprint dates and goals
4. Add tasks to sprint
5. Click Start Sprint

### For Members

#### Update Task Status
1. Open task
2. Change status dropdown
3. Status updated automatically
4. Team is notified

#### Add Comment
1. Open task
2. Scroll to Comments section
3. Type your comment
4. @mention team members if needed
5. Click Post

#### Attach File
1. Open task
2. Click "Attach File"
3. Select file from computer
4. Wait for upload
5. File appears in attachments list

## Feature Overview

### Task Management
- Create, update, delete tasks
- Assign tasks to team members
- Set priorities and due dates
- Track task status
- Add comments and attachments
- Task search and filtering

### Project Management
- Create and manage projects
- Sprint planning and tracking
- Project analytics and reporting
- Team member management
- Project timeline view

### Collaboration
- Real-time updates
- Task comments
- @mentions in comments
- File sharing
- Activity feed

### Notifications
- Real-time in-app notifications
- Email notifications
- Configurable preferences
- Task reminders
- Due date alerts

### Reporting & Analytics
- Task completion metrics
- Team performance
- Project progress
- Sprint burndown charts
- User activity reports

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + K` | Quick search |
| `C` | Create new task |
| `P` | Create new project |
| `/` | Focus search |
| `?` | Show all shortcuts |
| `Esc` | Close dialog |
| `Ctrl/Cmd + Enter` | Submit form |

## Best Practices

### For Effective Task Management
- ✅ Write clear, descriptive task titles
- ✅ Set realistic due dates
- ✅ Break large tasks into smaller ones
- ✅ Update task status regularly
- ✅ Add context in descriptions
- ✅ Use labels and priorities
- ✅ Communicate in task comments

### For Team Collaboration
- ✅ Use @mentions to notify specific people
- ✅ Keep comments professional and constructive
- ✅ Respond to task assignments promptly
- ✅ Update task progress regularly
- ✅ Attach relevant files and documents
- ✅ Use project channels for discussions

### For Project Management
- ✅ Plan sprints with realistic goals
- ✅ Review and adjust priorities regularly
- ✅ Keep project information up to date
- ✅ Monitor team workload and capacity
- ✅ Celebrate milestones and achievements
- ✅ Conduct sprint retrospectives

## Troubleshooting

### Can't Log In
- Verify email and password
- Check for password reset email
- Clear browser cache and cookies
- Try different browser
- Contact administrator if issue persists

### Not Receiving Notifications
1. Check notification preferences
2. Verify email address is correct
3. Check spam/junk folder
4. Ensure email is verified
5. Contact support if issue continues

### Can't See Tasks
- Verify you're in correct project
- Check filter settings
- Ensure tasks are assigned to you
- Refresh the page
- Check with project manager

### File Upload Issues
- Check file size (max 10MB)
- Verify file type is supported
- Check internet connection
- Try different browser
- Contact support for large files

## Support & Resources

### Getting Help

**Documentation**:
- Admin Guide: [USER_GUIDE_ADMIN.md](USER_GUIDE_ADMIN.md)
- Member Guide: [USER_GUIDE_MEMBER.md](USER_GUIDE_MEMBER.md)
- API Documentation: [API README](../api/README.md)
- FAQ: [Troubleshooting](../getting-started/TROUBLESHOOTING.md)

**Support Channels**:
- Email: support@taskmanager.example.com
- In-app chat: Click "Help" icon
- Knowledge base: https://help.taskmanager.example.com
- Community forum: https://community.taskmanager.example.com

**Training Resources**:
- Video tutorials: https://learn.taskmanager.example.com
- Webinars: Monthly training sessions
- Documentation: Complete guides and references

### Feedback & Feature Requests

We value your feedback! Share suggestions through:
- In-app feedback form
- Email: feedback@taskmanager.example.com
- Community forum feature requests
- Annual user survey

## Version History

| Version | Date | Major Changes |
|---------|------|---------------|
| 1.0.0 | Feb 2026 | Initial release |

---

**Need more help?** Contact support@taskmanager.example.com

**Last Updated**: February 2026
