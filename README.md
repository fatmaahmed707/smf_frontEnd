# SMF – Security Monitoring & Fortification

SMF is a full-stack smart security monitoring system designed to manage alerts, devices, users, zones, and emergency operations through a modern responsive dashboard.

The project combines:

- Flutter frontend application
- Spring Boot backend services
- Real-time monitoring interfaces
- Smart emergency dashboard
- Role & user management
- Device registry and monitoring
- Dark / Light mode modern UI

---

# Project Structure

```bash
smf/                -> Spring Boot Backend
smf_app_last2/      -> Flutter Frontend
````

---

# Features

## Authentication & Security

* Login & registration
* Role-based access control
* Admin / Engineer / Manager / Worker roles
* Secure authentication handling

## Dashboard

* Monitoring overview
* Alerts management
* Emergency dashboard
* Device statistics
* Real-time activity cards

## Roles Management

* Create roles
* Edit roles
* Delete roles
* View role details

## Users Management

* Add users
* Edit users
* Delete users
* User role assignment
* Responsive user cards

## Devices Management

* Device registry
* Device status monitoring
* Signal tracking
* Zone assignment
* Device actions

## Alerts System

* High / Medium / Low priority alerts
* Alert filtering
* Emergency notifications
* Alert status tracking

## UI/UX

* Modern futuristic interface
* Responsive layouts
* Dark mode
* Light mode
* Animated cards and glowing effects

---

# Technologies Used

## Frontend

* Flutter
* Dart
* Material UI
* Responsive Design

## Backend

* Spring Boot
* Java
* Maven
* REST APIs

## Database

* MySQL

---

# How to Run the Project

## Frontend

Navigate to frontend folder:

```bash
cd smf_app_last2
```

Install packages:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

## Backend

Navigate to backend folder:

```bash
cd smf
```

Run backend:

### Windows

```bash
mvnw.cmd spring-boot:run
```

### Linux / Mac

```bash
./mvnw spring-boot:run
```

---

# Screens Included

* Dashboard
* Emergency Dashboard
* Alerts Page
* Roles Management
* Users Management
* Devices Management
* Settings
* Profile
* Monitoring


```
```
