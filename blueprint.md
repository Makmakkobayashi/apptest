
# Project Blueprint

## Overview

This is a simple journal application that allows users to create, view, and delete journal entries. The app uses Firebase for authentication and Firestore for data storage.

## Features

*   **User Authentication:** Users can sign up and log in using their email and password.
*   **Journal Entries:** Users can create, view, and delete their journal entries.
*   **Firestore Integration:** Journal entries are stored in Firestore and retrieved in real-time.
*   **Routing:** The app uses the `go_router` package for navigation.

## File Structure

*   `lib/main.dart`: The main entry point of the application.
*   `lib/auth_gate.dart`: A widget that handles authentication state and redirects users accordingly.
*   `lib/auth_service.dart`: A class that handles user authentication with Firebase.
*   `lib/login_page.dart`: The login page UI.
*   `lib/registration_page.dart`: The registration page UI.
*   `lib/home_page.dart`: The home page that displays the list of journal entries.
*   `lib/add_journal_page.dart`: The page for adding a new journal entry.
*   `lib/journal_entry.dart`: The data model for a journal entry.
*   `lib/router.dart`: The routing configuration for the app.

## Current Task: Fix Redirect Loop

### Plan

1.  **Analyze the error:** The "too many redirects" error indicates a conflict in the navigation logic, likely between the `GoRouter`'s `redirect` and another part of the app managing authentication state.
2.  **Centralize Authentication Logic:** The `AuthGate` widget should be the single source of truth for handling authentication state.
3.  **Update `lib/auth_gate.dart`:**
    *   Implement a `StreamBuilder` that listens to `FirebaseAuth.instance.authStateChanges()`.
    *   If the user is logged in (`snapshot.hasData`), navigate to the `/home` screen using `context.go('/home')`.
    *   If the user is not logged in, display the `LoginPage`.
4.  **Update `lib/router.dart`:**
    *   Remove the `redirect` property from the `GoRouter` constructor to eliminate the conflicting navigation logic.
5.  **Verify the fix:** Run the application to ensure the redirect loop is resolved and the user is correctly navigated to the home screen after logging in.
