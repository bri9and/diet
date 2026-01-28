# Diet Tracking App - REST API Specification

**Version**: 2.0.0
**Date**: 2026-01-27
**Base URLs**:
- Production: `https://api.dietapp.com`
- Staging: `https://staging-api.dietapp.com` (Vercel)

## Overview

This API specification covers the Node.js/Express REST API for the diet tracking app. The API runs on:

- **Production**: Sebastian's bare metal server (Node.js + Express + MongoDB)
- **Staging**: Vercel serverless functions (same codebase)

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App                                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTPS (JWT Bearer)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Server                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────┐ │
│  │ Auth Middleware│─>│ Route Handlers │─>│ MongoDB            │ │
│  │ (Clerk JWT)    │  │ (Express)      │  │ (Mongoose)         │ │
│  └────────────────┘  └────────────────┘  └────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Clerk                                     │
│                  (JWT Verification via JWKS)                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [User Management](#2-user-management)
3. [Food Logging](#3-food-logging)
4. [Food Search](#4-food-search)
5. [Goals & Progress](#5-goals--progress)
6. [Weight Tracking](#6-weight-tracking)
7. [Family Sharing](#7-family-sharing)
8. [AI Processing](#8-ai-processing)
9. [Sync Endpoints](#9-sync-endpoints)
10. [Error Handling](#10-error-handling)

---

## 1. Authentication

All endpoints except `/health` require a valid Clerk JWT token.

### Headers

```
Authorization: Bearer <clerk_jwt_token>
Content-Type: application/json
```

### 1.1 Verify Session

Verify the current session is valid.

```
GET /auth/verify
```

**Response** `200 OK`:
```json
{
  "valid": true,
  "userId": "user_2abc123...",
  "email": "user@example.com",
  "sessionId": "sess_xyz..."
}
```

**Response** `401 Unauthorized`:
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token"
  }
}
```

---

## 2. User Management

### 2.1 Create/Sync User

Called after Clerk authentication to ensure user exists in our database.

```
POST /users/me
```

**Request Body** (optional - for initial setup):
```json
{
  "timezone": "America/Los_Angeles",
  "unitSystem": "metric",
  "language": "en"
}
```

**Response** `200 OK` (existing user) or `201 Created` (new user):
```json
{
  "id": "65abc123...",
  "clerkId": "user_2abc123...",
  "email": "user@example.com",
  "displayName": "John Doe",
  "avatarUrl": "https://...",
  "timezone": "America/Los_Angeles",
  "unitSystem": "metric",
  "language": "en",
  "subscriptionTier": "free",
  "shareWithFamily": false,
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-15T00:00:00Z"
}
```

### 2.2 Get Current User

```
GET /users/me
```

**Response** `200 OK`:
```json
{
  "id": "65abc123...",
  "clerkId": "user_2abc123...",
  "email": "user@example.com",
  "displayName": "John Doe",
  "avatarUrl": "https://...",
  "timezone": "America/Los_Angeles",
  "unitSystem": "metric",
  "language": "en",
  "subscriptionTier": "free",
  "subscriptionExpiresAt": null,
  "shareWithFamily": false,
  "aiProcessingConsent": true,
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-15T00:00:00Z"
}
```

### 2.3 Update User Profile

```
PATCH /users/me
```

**Request Body**:
```json
{
  "displayName": "John Smith",
  "timezone": "Europe/London",
  "unitSystem": "imperial",
  "shareWithFamily": true
}
```

**Response** `200 OK`:
```json
{
  "id": "65abc123...",
  "displayName": "John Smith",
  "timezone": "Europe/London",
  "unitSystem": "imperial",
  "shareWithFamily": true,
  "updatedAt": "2026-01-15T12:00:00Z"
}
```

### 2.4 Delete Account

Permanently deletes user account and all associated data.

```
DELETE /users/me
```

**Response** `200 OK`:
```json
{
  "success": true,
  "message": "Account and all associated data deleted"
}
```

---

## 3. Food Logging

### 3.1 Get Food Logs

Get food logs for a date range.

```
GET /food-logs?startDate=2026-01-01&endDate=2026-01-31
```

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| startDate | string | Yes | Start date (YYYY-MM-DD) |
| endDate | string | Yes | End date (YYYY-MM-DD) |
| mealType | string | No | Filter by meal type |

**Response** `200 OK`:
```json
{
  "logs": [
    {
      "id": "65abc123...",
      "userId": "65user...",
      "loggedDate": "2026-01-15",
      "loggedAt": "2026-01-15T12:30:00Z",
      "mealType": "lunch",
      "mealName": null,
      "entryMethod": "barcode",
      "items": [
        {
          "id": "65item123...",
          "foodId": "65food123...",
          "quantity": 1,
          "servingMultiplier": 1,
          "nutrition": {
            "calories": 350,
            "proteinG": 25,
            "carbsG": 30,
            "fatG": 12,
            "fiberG": 5,
            "sugarG": 8,
            "sodiumMg": 450
          },
          "foodSnapshot": {
            "name": "Grilled Chicken Sandwich",
            "brand": "Subway",
            "servingDescription": "1 sandwich (240g)"
          }
        }
      ],
      "totals": {
        "calories": 350,
        "proteinG": 25,
        "carbsG": 30,
        "fatG": 12,
        "itemCount": 1
      },
      "notes": null,
      "version": 1,
      "createdAt": "2026-01-15T12:30:00Z",
      "updatedAt": "2026-01-15T12:30:00Z"
    }
  ],
  "count": 1
}
```

### 3.2 Get Single Food Log

```
GET /food-logs/:id
```

**Response** `200 OK`: Same structure as single log above.

### 3.3 Create Food Log

```
POST /food-logs
```

**Request Body**:
```json
{
  "loggedDate": "2026-01-15",
  "loggedAt": "2026-01-15T12:30:00Z",
  "mealType": "lunch",
  "mealName": null,
  "entryMethod": "manual",
  "items": [
    {
      "foodId": "65food123...",
      "quantity": 1,
      "servingMultiplier": 1,
      "nutrition": {
        "calories": 350,
        "proteinG": 25,
        "carbsG": 30,
        "fatG": 12
      },
      "foodSnapshot": {
        "name": "Grilled Chicken Sandwich",
        "brand": "Subway",
        "servingDescription": "1 sandwich"
      }
    }
  ],
  "notes": "Had with water"
}
```

**Response** `201 Created`:
```json
{
  "id": "65abc123...",
  "loggedDate": "2026-01-15",
  "mealType": "lunch",
  "items": [...],
  "totals": {
    "calories": 350,
    "proteinG": 25,
    "carbsG": 30,
    "fatG": 12,
    "itemCount": 1
  },
  "version": 1,
  "createdAt": "2026-01-15T12:30:00Z"
}
```

### 3.4 Update Food Log

```
PATCH /food-logs/:id
```

**Request Body**:
```json
{
  "items": [
    {
      "id": "65item123...",
      "quantity": 2,
      "nutrition": {
        "calories": 700,
        "proteinG": 50,
        "carbsG": 60,
        "fatG": 24
      }
    }
  ],
  "notes": "Actually had two"
}
```

**Response** `200 OK`: Updated food log.

### 3.5 Delete Food Log

Soft delete a food log.

```
DELETE /food-logs/:id
```

**Response** `200 OK`:
```json
{
  "success": true,
  "id": "65abc123..."
}
```

### 3.6 Add Item to Food Log

```
POST /food-logs/:id/items
```

**Request Body**:
```json
{
  "foodId": "65food456...",
  "quantity": 1,
  "servingMultiplier": 0.5,
  "nutrition": {
    "calories": 150,
    "proteinG": 3,
    "carbsG": 20,
    "fatG": 7
  },
  "foodSnapshot": {
    "name": "Apple",
    "servingDescription": "1 medium apple"
  }
}
```

### 3.7 Quick Add Item (No Food Reference)

```
POST /food-logs/:id/items
```

**Request Body**:
```json
{
  "quickAddName": "Homemade soup",
  "quickAddDescription": "Vegetable soup from mom's recipe",
  "quantity": 1,
  "nutrition": {
    "calories": 200,
    "proteinG": 8,
    "carbsG": 25,
    "fatG": 6
  }
}
```

### 3.8 Remove Item from Food Log

```
DELETE /food-logs/:logId/items/:itemId
```

---

## 4. Food Search

### 4.1 Search Foods

Unified search across all sources.

```
GET /foods/search?q=chicken+breast&limit=20
```

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| q | string | required | Search query |
| limit | number | 20 | Max results (1-50) |
| sources | string | all | Comma-separated: cache,usda,openfoodfacts,custom |
| includeRecent | boolean | true | Include user's recent foods |

**Response** `200 OK`:
```json
{
  "results": [
    {
      "id": "65food123...",
      "source": "usda",
      "externalId": "usda_12345",
      "name": "Chicken breast, grilled",
      "brand": null,
      "servingSize": 100,
      "servingUnit": "g",
      "servingDescription": "100g serving",
      "nutrition": {
        "calories": 165,
        "proteinG": 31,
        "carbsG": 0,
        "fatG": 3.6
      },
      "photoUrl": null,
      "isRecent": true,
      "recentUsage": {
        "lastUsedAt": "2026-01-14T19:00:00Z",
        "useCount": 5,
        "preferredQuantity": 1.5
      }
    }
  ],
  "query": "chicken breast",
  "totalResults": 15,
  "sourcesQueried": ["cache", "recent", "usda"]
}
```

### 4.2 Barcode Lookup

```
GET /foods/barcode/:barcode
```

**Response** `200 OK`:
```json
{
  "found": true,
  "food": {
    "id": "65food456...",
    "source": "openfoodfacts",
    "barcode": "0123456789012",
    "name": "Organic Oat Milk",
    "brand": "Oatly",
    "servingSize": 240,
    "servingUnit": "ml",
    "nutrition": {
      "calories": 120,
      "proteinG": 3,
      "carbsG": 16,
      "fatG": 5
    },
    "photoUrl": "https://..."
  }
}
```

**Response** `404 Not Found`:
```json
{
  "found": false,
  "barcode": "0123456789012",
  "suggestion": "create_custom"
}
```

### 4.3 Get Food by ID

```
GET /foods/:id
```

**Response** `200 OK`:
```json
{
  "id": "65food123...",
  "source": "usda",
  "name": "Chicken breast, grilled",
  "brand": null,
  "servingSize": 100,
  "servingUnit": "g",
  "nutrition": {
    "calories": 165,
    "proteinG": 31,
    "carbsG": 0,
    "fatG": 3.6,
    "fiberG": 0,
    "sugarG": 0,
    "sodiumMg": 74,
    "saturatedFatG": 1,
    "cholesterolMg": 85
  },
  "extendedNutrition": {
    "vitaminAIu": 21,
    "calciumMg": 11,
    "ironMg": 1
  },
  "altServingSizes": [
    { "size": 85, "unit": "g", "description": "3 oz" },
    { "size": 170, "unit": "g", "description": "6 oz (large breast)" }
  ]
}
```

### 4.4 Create Custom Food

```
POST /foods
```

**Request Body**:
```json
{
  "name": "Grandma's Apple Pie",
  "brand": null,
  "servingSize": 150,
  "servingUnit": "g",
  "servingDescription": "1 slice (150g)",
  "nutrition": {
    "calories": 320,
    "proteinG": 3,
    "carbsG": 45,
    "fatG": 14,
    "sugarG": 28
  },
  "isPublic": false
}
```

**Response** `201 Created`:
```json
{
  "id": "65custom123...",
  "source": "custom",
  "createdByUserId": "65user...",
  "name": "Grandma's Apple Pie",
  "isPublic": false,
  ...
}
```

### 4.5 Get Recent Foods

```
GET /foods/recent?limit=50
```

**Response** `200 OK`:
```json
{
  "recentFoods": [
    {
      "id": "65recent123...",
      "foodId": "65food123...",
      "useCount": 15,
      "lastUsedAt": "2026-01-15T12:00:00Z",
      "preferredQuantity": 1,
      "preferredServingMultiplier": 1.5,
      "commonMealType": "breakfast",
      "food": {
        "id": "65food123...",
        "name": "Greek Yogurt",
        "brand": "Fage",
        "nutrition": {
          "calories": 100
        }
      }
    }
  ]
}
```

---

## 5. Goals & Progress

### 5.1 Get Active Goal

```
GET /goals/active
```

**Response** `200 OK`:
```json
{
  "goal": {
    "id": "65goal123...",
    "userId": "65user...",
    "goalType": "weight_loss",
    "goalName": "Summer shred",
    "caloriesTarget": 1800,
    "proteinTargetG": 120,
    "carbsTargetG": 180,
    "fatTargetG": 60,
    "fiberTargetG": 30,
    "currentWeightKg": 85,
    "targetWeightKg": 75,
    "heightCm": 178,
    "activityLevel": "moderate",
    "targetDate": "2026-06-01",
    "weeklyChangeKg": -0.5,
    "isActive": true,
    "startedAt": "2026-01-01",
    "createdAt": "2026-01-01T00:00:00Z"
  }
}
```

**Response** `404 Not Found` (no active goal):
```json
{
  "goal": null,
  "message": "No active goal found"
}
```

### 5.2 Create/Update Goal

```
POST /goals
```

**Request Body**:
```json
{
  "goalType": "weight_loss",
  "goalName": "Summer shred",
  "caloriesTarget": 1800,
  "proteinTargetG": 120,
  "carbsTargetG": 180,
  "fatTargetG": 60,
  "currentWeightKg": 85,
  "targetWeightKg": 75,
  "heightCm": 178,
  "birthDate": "1990-05-15",
  "sex": "male",
  "activityLevel": "moderate",
  "targetDate": "2026-06-01",
  "weeklyChangeKg": -0.5
}
```

**Response** `201 Created`: New goal (previous active goal deactivated).

### 5.3 Get Daily Summary

```
GET /summaries/daily/:date
```

**Response** `200 OK`:
```json
{
  "summary": {
    "id": "65summary123...",
    "userId": "65user...",
    "summaryDate": "2026-01-15",
    "totals": {
      "calories": 1650,
      "proteinG": 95,
      "carbsG": 180,
      "fatG": 55,
      "fiberG": 22,
      "sugarG": 45,
      "sodiumMg": 1800
    },
    "mealBreakdown": {
      "breakfast": { "calories": 400, "itemCount": 3 },
      "lunch": { "calories": 550, "itemCount": 2 },
      "dinner": { "calories": 600, "itemCount": 4 },
      "snack": { "calories": 100, "itemCount": 1 }
    },
    "totalMeals": 4,
    "totalItems": 10,
    "goalSnapshot": {
      "caloriesTarget": 1800,
      "proteinTargetG": 120
    },
    "completion": {
      "caloriesPercent": 91.67,
      "proteinPercent": 79.17
    },
    "computedAt": "2026-01-15T23:00:00Z"
  }
}
```

### 5.4 Get Summary Range

```
GET /summaries/range?startDate=2026-01-01&endDate=2026-01-31
```

**Response** `200 OK`:
```json
{
  "summaries": [
    { "summaryDate": "2026-01-01", "totals": {...} },
    { "summaryDate": "2026-01-02", "totals": {...} }
  ],
  "aggregates": {
    "avgCalories": 1720,
    "avgProteinG": 98,
    "daysLogged": 15,
    "avgCalorieAdherence": 95.5
  }
}
```

### 5.5 Calculate TDEE

Calculate recommended daily calories based on user metrics.

```
POST /goals/calculate-tdee
```

**Request Body**:
```json
{
  "weightKg": 85,
  "heightCm": 178,
  "age": 35,
  "sex": "male",
  "activityLevel": "moderate",
  "goalType": "weight_loss",
  "weeklyChangeKg": -0.5
}
```

**Response** `200 OK`:
```json
{
  "bmr": 1820,
  "tdee": 2821,
  "recommendedCalories": 2321,
  "recommendedMacros": {
    "proteinG": 145,
    "carbsG": 232,
    "fatG": 77
  },
  "deficitCalories": 500,
  "formulaUsed": "mifflin_st_jeor"
}
```

---

## 6. Weight Tracking

### 6.1 Get Weight Logs

```
GET /weight-logs?startDate=2026-01-01&endDate=2026-01-31
```

**Response** `200 OK`:
```json
{
  "logs": [
    {
      "id": "65weight123...",
      "weightKg": 84.5,
      "measuredAt": "2026-01-15T07:30:00Z",
      "measuredDate": "2026-01-15",
      "bodyFatPercentage": 22.5,
      "source": "smart_scale",
      "notes": "After morning workout"
    }
  ],
  "stats": {
    "startWeight": 85.0,
    "currentWeight": 84.5,
    "change": -0.5,
    "avgWeeklyChange": -0.25
  }
}
```

### 6.2 Log Weight

```
POST /weight-logs
```

**Request Body**:
```json
{
  "weightKg": 84.2,
  "measuredAt": "2026-01-16T07:00:00Z",
  "bodyFatPercentage": 22.3,
  "source": "manual",
  "notes": "Feeling good"
}
```

**Response** `201 Created`: New weight log.

---

## 7. Family Sharing

### 7.1 Get My Families

```
GET /families
```

**Response** `200 OK`:
```json
{
  "families": [
    {
      "id": "65family123...",
      "name": "Smith Family",
      "memberCount": 3,
      "myRole": "owner",
      "mySharingSettings": {
        "shareFoodLogs": true,
        "shareGoals": false,
        "shareWeight": false
      }
    }
  ]
}
```

### 7.2 Get Family Details

```
GET /families/:id
```

**Response** `200 OK`:
```json
{
  "family": {
    "id": "65family123...",
    "name": "Smith Family",
    "description": "Our household",
    "createdByUserId": "65user...",
    "maxMembers": 6,
    "createdAt": "2026-01-01T00:00:00Z"
  },
  "members": [
    {
      "id": "65member123...",
      "userId": "65user...",
      "displayName": "John Doe",
      "avatarUrl": "https://...",
      "role": "owner",
      "joinedAt": "2026-01-01T00:00:00Z",
      "sharingSettings": {
        "shareFoodLogs": true,
        "shareGoals": false
      }
    }
  ]
}
```

### 7.3 Create Family

```
POST /families
```

**Request Body**:
```json
{
  "name": "Smith Family",
  "description": "Our household diet tracking"
}
```

**Response** `201 Created`: New family with creator as owner.

### 7.4 Invite Family Member

```
POST /families/:id/invites
```

**Request Body**:
```json
{
  "email": "spouse@example.com",
  "proposedRole": "member",
  "message": "Join our family's meal tracking!"
}
```

**Response** `201 Created`:
```json
{
  "invite": {
    "id": "65invite123...",
    "inviteCode": "ABC123XY",
    "inviteLink": "https://dietapp.com/invite/ABC123XY",
    "expiresAt": "2026-01-22T00:00:00Z"
  }
}
```

### 7.5 Accept Family Invite

```
POST /families/invites/accept
```

**Request Body**:
```json
{
  "inviteCode": "ABC123XY"
}
```

**Response** `200 OK`:
```json
{
  "success": true,
  "familyId": "65family123...",
  "familyName": "Smith Family",
  "role": "member"
}
```

### 7.6 Update My Sharing Settings

```
PATCH /families/:id/membership
```

**Request Body**:
```json
{
  "shareFoodLogs": true,
  "shareGoals": false,
  "shareWeight": false
}
```

### 7.7 Get Family Members' Food Logs

```
GET /families/:id/food-logs?date=2026-01-15
```

**Response** `200 OK`:
```json
{
  "logs": [
    {
      "userId": "65user456...",
      "displayName": "Jane Doe",
      "logs": [
        {
          "id": "65log...",
          "mealType": "breakfast",
          "totals": { "calories": 400 }
        }
      ]
    }
  ]
}
```

---

## 8. AI Processing

### 8.1 Process Food Photo

```
POST /ai/process-photo
Content-Type: multipart/form-data
```

**Form Data**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| photo | file | Yes | Image file (JPEG/PNG) |
| mealType | string | No | Hint: breakfast/lunch/dinner/snack |

**Response** `200 OK`:
```json
{
  "success": true,
  "identifiedItems": [
    {
      "name": "Grilled Salmon",
      "confidence": 0.92,
      "estimatedPortion": "6 oz",
      "estimatedPortionG": 170,
      "matchedFood": {
        "id": "65food123...",
        "source": "usda",
        "name": "Salmon, Atlantic, Grilled",
        "nutrition": {
          "calories": 367,
          "proteinG": 40,
          "carbsG": 0,
          "fatG": 22
        }
      }
    },
    {
      "name": "Steamed Broccoli",
      "confidence": 0.88,
      "estimatedPortion": "1 cup",
      "estimatedPortionG": 91,
      "matchedFood": {
        "id": "65food456...",
        "source": "usda",
        "name": "Broccoli, Steamed",
        "nutrition": {
          "calories": 31,
          "proteinG": 2.5,
          "carbsG": 6,
          "fatG": 0.4
        }
      }
    }
  ],
  "totalEstimated": {
    "calories": 398,
    "proteinG": 42.5,
    "carbsG": 6,
    "fatG": 22.4
  },
  "processingTimeMs": 1250
}
```

**Note**: Photo is processed and immediately deleted per privacy policy.

### 8.2 Parse Natural Language

```
POST /ai/parse-text
```

**Request Body**:
```json
{
  "text": "I had 2 eggs scrambled with cheese and a slice of whole wheat toast",
  "mealType": "breakfast"
}
```

**Response** `200 OK`:
```json
{
  "parsedItems": [
    {
      "rawText": "2 eggs scrambled",
      "matchedFood": {
        "id": "65food...",
        "name": "Eggs, Scrambled"
      },
      "quantity": 2,
      "servingMultiplier": 1,
      "nutrition": {
        "calories": 204,
        "proteinG": 14
      }
    }
  ],
  "total": {
    "calories": 386,
    "proteinG": 24.6
  }
}
```

### 8.3 Get Weekly Insights

```
GET /ai/insights?startDate=2026-01-08&endDate=2026-01-14
```

**Response** `200 OK`:
```json
{
  "insights": [
    {
      "type": "goal_progress",
      "title": "On Track This Week",
      "message": "You stayed within 100 calories of your goal 5 out of 7 days.",
      "sentiment": "positive"
    },
    {
      "type": "nutrient_alert",
      "title": "Protein Intake Low",
      "message": "Averaging 85g protein/day, 35g below target. Consider adding Greek yogurt or eggs.",
      "sentiment": "warning"
    }
  ],
  "summary": {
    "avgCalories": 1720,
    "avgProteinG": 85,
    "goalAdherencePercent": 71
  }
}
```

### 8.4 Check AI Usage

```
GET /ai/usage
```

**Response** `200 OK`:
```json
{
  "usage": {
    "photoRecognition": { "used": 3, "limit": 5, "remaining": 2 },
    "naturalLanguage": { "used": 7, "limit": 10, "remaining": 3 },
    "insights": { "used": 0, "limit": 0, "remaining": 0 }
  },
  "tier": "free",
  "resetsAt": "2026-02-01T00:00:00Z"
}
```

---

## 9. Sync Endpoints

See [ADR-005: Sync Protocol](/architecture/adrs/ADR-005-sync-protocol.md) for detailed sync documentation.

### 9.1 Push Changes

```
POST /sync/push
```

**Request Body**:
```json
{
  "deviceId": "device-uuid",
  "lastPulledAt": "2026-01-15T10:00:00Z",
  "changes": [
    {
      "collection": "foodLogs",
      "operation": "create",
      "documentId": "local-uuid",
      "version": 1,
      "data": { ... },
      "timestamp": "2026-01-15T10:30:00Z"
    }
  ]
}
```

**Response** `200 OK`:
```json
{
  "success": true,
  "applied": ["local-uuid"],
  "conflicts": [],
  "serverTime": "2026-01-15T10:35:00Z"
}
```

### 9.2 Pull Changes

```
GET /sync/pull?since=2026-01-15T10:00:00Z&collections=foodLogs,weightLogs
```

**Response** `200 OK`:
```json
{
  "changes": [
    {
      "collection": "foodLogs",
      "documentId": "65abc...",
      "operation": "upsert",
      "data": { ... },
      "version": 2,
      "updatedAt": "2026-01-15T10:20:00Z"
    }
  ],
  "serverTime": "2026-01-15T10:35:00Z",
  "hasMore": false
}
```

### 9.3 Full Sync (Initial)

```
POST /sync/full
```

**Response** `200 OK`:
```json
{
  "data": {
    "foodLogs": [...],
    "weightLogs": [...],
    "userGoals": [...],
    "dailySummaries": [...],
    "recentFoods": [...]
  },
  "serverTime": "2026-01-15T10:35:00Z"
}
```

---

## 10. Error Handling

### Standard Error Response

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {}
  }
}
```

### HTTP Status Codes

| Code | Meaning | When Used |
|------|---------|-----------|
| 200 | OK | Successful GET, PATCH, POST (update) |
| 201 | Created | Successful POST (create) |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid request body |
| 401 | Unauthorized | Missing/invalid JWT |
| 403 | Forbidden | Access denied |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate/version conflict |
| 422 | Unprocessable Entity | Validation error |
| 429 | Too Many Requests | Rate limited |
| 500 | Internal Server Error | Server error |

### Error Codes

| Code | Description |
|------|-------------|
| `UNAUTHORIZED` | Invalid or expired JWT |
| `FORBIDDEN` | Access denied to resource |
| `NOT_FOUND` | Resource not found |
| `VALIDATION_ERROR` | Request validation failed |
| `RATE_LIMITED` | Too many requests |
| `CONFLICT` | Version conflict during sync |
| `AI_LIMIT_EXCEEDED` | AI usage limit reached |
| `AI_PROCESSING_ERROR` | AI service failed |
| `FAMILY_LIMIT_REACHED` | Max family members reached |
| `INTERNAL_ERROR` | Unexpected server error |

### Rate Limits

| Endpoint Type | Limit |
|---------------|-------|
| Auth endpoints | 10/minute |
| Read operations | 120/minute |
| Write operations | 60/minute |
| AI Processing | 10/minute |
| Sync endpoints | 30/minute |

Rate limit headers:
```
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 115
X-RateLimit-Reset: 1706371200
```

---

## Health Check

```
GET /health
```

No authentication required.

**Response** `200 OK`:
```json
{
  "status": "healthy",
  "version": "2.0.0",
  "timestamp": "2026-01-15T12:00:00Z",
  "services": {
    "mongodb": "connected",
    "clerk": "connected"
  }
}
```

---

## Environment Variables

### Production (Bare Metal)

```bash
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb://localhost:27017/dietapp
CLERK_SECRET_KEY=sk_live_xxx
CLERK_PUBLISHABLE_KEY=pk_live_xxx
OPENAI_API_KEY=sk-xxx
ANTHROPIC_API_KEY=sk-ant-xxx
```

### Staging (Vercel)

```bash
NODE_ENV=staging
MONGODB_URI=mongodb+srv://xxx.mongodb.net/dietapp-staging
CLERK_SECRET_KEY=sk_test_xxx
CLERK_PUBLISHABLE_KEY=pk_test_xxx
```

---

## Project Structure

```
api/
├── src/
│   ├── index.ts              # Express app entry
│   ├── middleware/
│   │   ├── auth.ts           # Clerk JWT verification
│   │   ├── rateLimit.ts      # Rate limiting
│   │   └── errorHandler.ts   # Global error handler
│   ├── routes/
│   │   ├── users.ts
│   │   ├── foodLogs.ts
│   │   ├── foods.ts
│   │   ├── goals.ts
│   │   ├── weightLogs.ts
│   │   ├── families.ts
│   │   ├── ai.ts
│   │   └── sync.ts
│   ├── models/               # Mongoose models
│   │   ├── User.ts
│   │   ├── FoodLog.ts
│   │   ├── Food.ts
│   │   └── ...
│   └── services/
│       ├── foodSearch.ts
│       ├── aiService.ts
│       └── syncService.ts
├── vercel.json               # Vercel configuration
├── package.json
└── tsconfig.json
```
