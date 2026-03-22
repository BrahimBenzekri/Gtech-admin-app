# Admin Mobile App – GTech

## Overview
A private mobile application built with Flutter natively for Android and iOS, intended exclusively for the owner and employees across 4 stores. It serves as the administrative backend for managing users, products, and price requests.

## Tech Stack
- **Framework:** Flutter (Android APK + iOS)
- **State Management:** flutter_riverpod
- **Routing:** go_router
- **Backend/BaaS:** Firebase (Auth, Firestore, Storage)
- **UI/UX Packages:** flutter_screenutil, cached_network_image
- **Device Features:** image_picker

## Features
- **Admin Authentication:** Secure login for administrators and authorized employees.
- **Real-Time CRUD:** Full real-time Create, Read, Update, Delete capabilities for:
  - Users (Admins, Employees, Clients with custom discount percentages)
  - Products (Details, stock, store assignments)
  - Price Requests (Inquiries from clients)

## Brand Guidelines
- **Primary Blue:** `#0044FF`
- **Accent Teal:** `#00D4C8`
- **Dark Text/BG:** `#0F172A`
- **Light BG/Cards:** `#F8FAFC`

## Project Structure (Data)
- `users`: Store user roles (admin, employee, client) and discount percentages.
- `products`: Store product details, categories, prices, inventory status, and images.
- `price_requests`: Track incoming client requests for specific products.

## Delivery Requirements
- Real-time performance.
- Android APK & iOS delivery.
- Exact match of brand colors.
