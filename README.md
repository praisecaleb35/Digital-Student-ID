# 🎓 IDChain - Digital Student ID System

A decentralized student identity system built on Stacks blockchain for campus access, event registration, and student verification.

## 🌟 Features

### 👨‍🎓 Student Management
- **Student Registration** - Register new students with personal and academic information
- **Identity Verification** - Verify student identity using wallet addresses
- **Status Management** - Update student status (active, suspended, graduated)
- **GPA Tracking** - Maintain and update student academic performance

### 🎉 Event System
- **Event Creation** - Create campus events with capacity limits
- **Event Registration** - Students can register for events
- **Attendance Tracking** - Confirm student attendance at events
- **Verification Requirements** - Set events to require verified students only

### 🔐 Access Control
- **Resource Access** - Grant/revoke access to campus resources
- **Time-based Permissions** - Set expiring access permissions
- **Department Admin** - Assign department administrators

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone the repository
```bash
git clone https://github.com/praisecaleb35/Digital-Student-ID
cd Digital-Student-ID
```

2. Check contract compilation
```bash
clarinet check
```

3. Run tests
```bash
clarinet test
```

## 📖 Usage Guide

### Student Registration

Register a new student:
```clarity
(contract-call? .IDChain register-student 
  "John Doe" 
  "john.doe@university.edu" 
  "STU2024001" 
  "Computer Science" 
  u2)
```

### Event Management

Create a new event:
```clarity
(contract-call? .IDChain create-event
  "Tech Symposium 2024"
  "Annual technology symposium featuring latest innovations"
  u100
  u144000  ;; event date in block height
  "Main Auditorium"
  true)    ;; requires verification
```

Register for an event:
```clarity
(contract-call? .IDChain register-for-event u1)
```

### Access Control

Grant access to a resource:
```clarity
(contract-call? .IDChain grant-access 
  u1           ;; student-id
  "library"    ;; resource name
  u52560)      ;; expiry in blocks (~1 year)
```

Check if student has access:
```clarity
(contract-call? .IDChain has-access u1 "library")
```

## 🔍 Read-Only Functions

### Student Information
- `get-student-info` - Get student details by ID
- `get-student-by-wallet` - Get student info by wallet address
- `verify-student` - Verify if a wallet belongs to an active student
- `get-student-count` - Total number of registered students

### Event Information
- `get-event-info` - Get event details by ID
- `is-registered-for-event` - Check if student is registered for event
- `get-event-count` - Total number of events created

### Access Control
- `has-access` - Check if student has access to a resource
- `get-department-admin` - Get admin for a department

## 🏗️ Contract Architecture

### Data Structures

#### Students Map
```clarity
{
  wallet: principal,
  name: string,
  email: string,
  student-number: string,
  department: string,
  year: uint,
  gpa: uint,
  status: string,
  registration-block: uint,
  last-updated: uint
}
```

#### Events Map
```clarity
{
  name: string,
  description: string,
  organizer: principal,
  max-capacity: uint,
  current-attendance: uint,
  event-date: uint,
  location: string,
  requires-verification: bool,
  status: string
}
```

## ⚠️ Error Codes

| Code | Error | Description |
|------|--------|-------------|
| 100 | ERR-UNAUTHORIZED | Caller lacks required permissions |
| 101 | ERR-STUDENT-NOT-FOUND | Student ID does not exist |
| 102 | ERR-ALREADY-REGISTERED | Student already registered |
| 103 | ERR-INVALID-STATUS | Invalid student status |
| 104 | ERR-ACCESS-DENIED | Access permission denied |
| 105 | ERR-EVENT-NOT-FOUND | Event ID does not exist |
| 106 | ERR-ALREADY-REGISTERED-EVENT | Already registered for event |
| 107 | ERR-EVENT-FULL | Event capacity reached |
| 108 | ERR-INVALID-DEPARTMENT | Invalid department name |

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Links

- [Stacks Blockchain](https://stacks.org/)
- [Clarity Language](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)

---

Built with ❤️ for the future of decentralized education
