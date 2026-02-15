# Documentation Index

Welcome to the **Flutter Notification Queue (FNQ)** documentation. This directory contains detailed information about the library's components, configuration, and usage.

## Getting Started
- [**Installation & Setup**](getting_started.md): Quick start guide to integrate FNQ into your app.

## Modules

### Core Engine
The heart of the notification system.
- [**Overview**](core/README.md): How `FlutterNotificationQueue`, `ConfigurationManager`, and `QueueCoordinator` work together.
- [**API Reference**](core/api.md): Detailed breakdown of public and internal components.
- [**Architecture**](core/architecture.md): High-level system design and data flow.
- [**Lifecycle**](core/lifecycle.md): Understanding the notification lifecycle from creation to dismissal.

### Queue System
Manages where and how notifications appear.
- [**Overview**](queue/README.md): Understanding `NotificationQueue` and `QueuePosition`.
- [**Queue Styles**](queue/styles.md): Configuring appearance (Filled, Flat, Outlined) and animations.

### Channel System
Categorizes notifications by intent (Success, Error, Info).
- [**Overview**](channel/README.md): Understanding `NotificationChannel` and its role.
- [**Standard Channels**](channel/standard_channels.md): Using the built-in channel presets.

### Overlay & Rendering
Handles the visual presentation of notifications.
- [**Overview**](overlay/README.md): How `NotificationOverlay` integrates with the widget tree.

## Contributing
- [**Contributing Guidelines**](../CONTRIBUTING.md): How to contribute to the project.
