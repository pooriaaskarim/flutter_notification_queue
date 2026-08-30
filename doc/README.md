# Documentation Index

Welcome to the **Flutter Notification Queue (FNQ)** documentation index. This directory contains detailed architectural guides, API breakdowns, and migration documentation for **v0.4.x**.

---

## 🚀 Getting Started & Migration

- [**Getting Started**](getting_started.md): Quick start guide to integrate FNQ v0.4.x into your app using `NotificationController` and `NotificationScope`.
- [**Migration Guide (v0.3.x → v0.4.0)**](migration_v0_4.md): Step-by-step instructions for migrating from legacy static singletons to the decoupled v0.4.x architecture.
- [**Architecture Proposal & Design Blueprint**](architecture_v0_4_proposal.md): Detailed technical specification of multi-tenancy, state ownership, gesture intents, and event streams.

---

## 📦 Modules & Core Subsystems

### Core Engine
The central nervous system of FNQ in v0.4.x.
- [**Overview**](core/README.md): How `NotificationController`, `NotificationScope`, `ConfigurationManager`, and `QueueCoordinator` work together.
- [**API Reference**](core/api.md): Detailed breakdown of public and internal components.
- [**Architecture**](core/architecture.md): High-level system design and data flow.
- [**Lifecycle**](core/lifecycle.md): Understanding the notification lifecycle from creation to dismissal.

### Queue System
Manages spatial positioning and stacking layout.
- [**Overview**](queue/README.md): Understanding `NotificationQueue` and `QueuePosition`.
- [**Queue Styles**](queue/styles.md): Configuring appearance (Stacked, Flat, Outlined) and layout rules.

### Channel System
Categorizes notifications by intent (Success, Error, Info, Warning, Chat, etc.).
- [**Overview**](channel/README.md): Understanding `NotificationChannel` and visual properties.
- [**Standard Channels**](channel/standard_channels.md): Using the built-in channel presets.

### Overlay & Rendering
Handles the visual presentation of notifications on the screen.
- [**Overview**](overlay/README.md): How `NotificationOverlay` integrates with the widget tree via `NotificationScope`.

---

## 🤝 Contributing

- [**Contributing Guidelines**](../CONTRIBUTING.md): How to contribute to the project.
