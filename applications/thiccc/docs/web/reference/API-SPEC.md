# API Specification

**Style Guide:** This API follows the [Google JSON Style Guide](https://google.github.io/styleguide/jsoncstyleguide.xml)

**Base URL (Development):** `http://localhost:8000`  
**Base URL (Production):** `https://api.thiccc.app`

**Authentication:** All protected endpoints require `Authorization: Bearer <jwt>` header (Clerk JWT)

**Response Format:** All responses wrap data in a `data` object. Lists use an `items` array with pagination metadata.

**Key Conventions (per Google JSON Style Guide):**
- Property names use `camelCase`
- All successful responses wrapped in `data` object
- Collections use `items` array (always last property in parent)
- Pagination uses: `currentItemCount`, `itemsPerPage`, `startIndex`, `totalItems`
- Error responses use `error` object with `code`, `message`, and optional `errors` array
- Timestamps in ISO 8601 format with timezone (e.g., `2025-01-15T10:00:00Z`)

---

## Health Check

### GET /health

Returns API health status.

**Authentication:** None

**Response:** `200 OK`
```json
"OK"
```

---

## User Endpoints

### GET /api/me

Get current user information.

**Authentication:** Required

**Response:** `200 OK`
```json
{
  "data": {
    "id": "user_abc123",
    "email": "user@example.com",
    "roles": ["admin", "trainer"]
  }
}
```

**Note:** `roles` is an array. Users can have multiple roles (e.g., a user can be both "trainer" and "user").

---

## Workout Endpoints

### POST /api/workouts

Create a complete workout with exercises and sets in one atomic request.

**Authentication:** Required

**Request Body:**
```json
{
  "name": "Leg Day",
  "notes": "Feeling strong today",
  "startedAt": "2025-01-15T10:00:00Z",
  "completedAt": "2025-01-15T11:30:00Z",
  "exercises": [
    {
      "name": "Squat",
      "orderIndex": 0,
      "notes": "Deep squats",
      "sets": [
        {
          "weight": 225.0,
          "reps": 5,
          "rpe": 8,
          "completedAt": "2025-01-15T10:15:00Z"
        },
        {
          "weight": 225.0,
          "reps": 5,
          "rpe": 9,
          "completedAt": "2025-01-15T10:18:00Z"
        },
        {
          "weight": 235.0,
          "reps": 3,
          "rpe": 9,
          "completedAt": "2025-01-15T10:22:00Z"
        }
      ]
    },
    {
      "name": "Romanian Deadlift",
      "orderIndex": 1,
      "notes": "",
      "sets": [
        {
          "weight": 185.0,
          "reps": 8,
          "rpe": 7,
          "completedAt": "2025-01-15T10:30:00Z"
        },
        {
          "weight": 185.0,
          "reps": 8,
          "rpe": 8,
          "completedAt": "2025-01-15T10:33:00Z"
        }
      ]
    }
  ]
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "id": "workout_123",
    "userId": "user_abc",
    "name": "Leg Day",
    "notes": "Feeling strong today",
    "startedAt": "2025-01-15T10:00:00Z",
    "completedAt": "2025-01-15T11:30:00Z",
    "exercises": [
      {
        "id": "exercise_456",
        "workoutId": "workout_123",
        "name": "Squat",
        "orderIndex": 0,
        "notes": "Deep squats",
        "sets": [
          {
            "id": "set_789",
            "exerciseId": "exercise_456",
            "weight": 225.0,
            "reps": 5,
            "rpe": 8,
            "completedAt": "2025-01-15T10:15:00Z"
          },
          {
            "id": "set_790",
            "exerciseId": "exercise_456",
            "weight": 225.0,
            "reps": 5,
            "rpe": 9,
            "completedAt": "2025-01-15T10:18:00Z"
          },
          {
            "id": "set_791",
            "exerciseId": "exercise_456",
            "weight": 235.0,
            "reps": 3,
            "rpe": 9,
            "completedAt": "2025-01-15T10:22:00Z"
          }
        ]
      },
      {
        "id": "exercise_457",
        "workoutId": "workout_123",
        "name": "Romanian Deadlift",
        "orderIndex": 1,
        "notes": "",
        "sets": [
          {
            "id": "set_792",
            "exerciseId": "exercise_457",
            "weight": 185.0,
            "reps": 8,
            "rpe": 7,
            "completedAt": "2025-01-15T10:30:00Z"
          },
          {
            "id": "set_793",
            "exerciseId": "exercise_457",
            "weight": 185.0,
            "reps": 8,
            "rpe": 8,
            "completedAt": "2025-01-15T10:33:00Z"
          }
        ]
      }
    ]
  }
}
```

**Notes:**
- This is the primary endpoint for creating workouts from the web interface
- Submit the entire workout as one atomic transaction
- All exercises and sets are created together
- Server assigns IDs to workout, exercises, and sets

---

### GET /api/workouts

List user's workouts.

**Authentication:** Required

**Query Parameters:**
- `limit` (optional): Max results per page (default: 50)
- `offset` (optional): Pagination offset (default: 0)
- `sort` (optional): `date_asc` | `date_desc` (default: `date_desc`)

**Response:** `200 OK`
```json
{
  "data": {
    "currentItemCount": 10,
    "itemsPerPage": 50,
    "startIndex": 0,
    "totalItems": 42,
    "items": [
      {
        "id": "workout_123",
        "userId": "user_abc",
        "name": "Leg Day",
        "startedAt": "2025-01-15T10:00:00Z",
        "completedAt": "2025-01-15T11:30:00Z"
      }
    ]
  }
}
```

---

### GET /api/workouts/:id

Get single workout with all exercises and sets.

**Authentication:** Required

**Response:** `200 OK`
```json
{
  "data": {
    "id": "workout_123",
    "userId": "user_abc",
    "name": "Leg Day",
    "startedAt": "2025-01-01T10:00:00Z",
    "completedAt": "2025-01-01T11:30:00Z",
    "exercises": [
      {
        "id": "exercise_456",
        "workoutId": "workout_123",
        "name": "Squat",
        "orderIndex": 0,
        "sets": [
          {
            "id": "set_789",
            "exerciseId": "exercise_456",
            "weight": 225.0,
            "reps": 5,
            "completedAt": "2025-01-01T10:15:00Z",
            "rpe": 8
          }
        ]
      }
    ]
  }
}
```

---

### PATCH /api/workouts/:id

Update workout details (name, notes, timestamps).

**Authentication:** Required (must own workout)

**Request Body:** (all fields optional)
```json
{
  "name": "Updated name",
  "notes": "Updated notes",
  "completedAt": "2025-01-01T12:00:00Z"
}
```

**Response:** `200 OK` (updated workout object wrapped in `data`)

**Notes:**
- For editing workout metadata only
- To modify exercises/sets, use their respective PATCH endpoints

---

### DELETE /api/workouts/:id

Delete workout and all associated exercises/sets.

**Authentication:** Required

**Response:** `204 No Content`

---

## Exercise Endpoints

### POST /api/workouts/:workoutId/exercises

Add exercise to an existing workout.

**Authentication:** Required (must own workout)

**Request Body:**
```json
{
  "name": "Bench Press",
  "orderIndex": 0,
  "notes": "Pause reps"
}
```

**Response:** `201 Created` (exercise object wrapped in `data`)

**Notes:**
- Use this to add exercises to existing workouts during editing
- Most new workouts should use `POST /api/workouts` with nested exercises

---

### PATCH /api/exercises/:id

Update exercise details.

**Authentication:** Required (must own workout)

**Request Body:** (all fields optional)
```json
{
  "name": "Updated name",
  "notes": "Updated notes",
  "orderIndex": 1
}
```

**Response:** `200 OK` (updated exercise wrapped in `data`)

**Notes:**
- For editing existing exercises
- Reorder exercises by updating `orderIndex`

---

### DELETE /api/exercises/:id

Delete exercise and all associated sets.

**Authentication:** Required (must own workout)

**Response:** `204 No Content`

**Notes:**
- Cascade deletes all sets belonging to this exercise
- Cannot be undone

---

## Set Endpoints

### POST /api/exercises/:exerciseId/sets

Add set to an existing exercise.

**Authentication:** Required (must own workout)

**Request Body:**
```json
{
  "weight": 185.0,
  "reps": 8,
  "rpe": 7,
  "completedAt": "2025-01-15T10:30:00Z"
}
```

**Response:** `201 Created` (set object wrapped in `data`)

**Notes:**
- Use this to add sets to existing exercises during editing
- Most new workouts should use `POST /api/workouts` with nested sets

---

### PATCH /api/sets/:id

Update set details.

**Authentication:** Required (must own workout)

**Request Body:** (all fields optional)
```json
{
  "weight": 190.0,
  "reps": 8,
  "rpe": 8,
  "completedAt": "2025-01-15T10:32:00Z"
}
```

**Response:** `200 OK` (updated set wrapped in `data`)

**Notes:**
- For editing individual sets
- Typical workflow: user edits one set at a time in UI
- Each set update is a separate PATCH request

---

### DELETE /api/sets/:id

Delete set.

**Authentication:** Required (must own workout)

**Response:** `204 No Content`

**Notes:**
- Removes individual set
- Cannot be undone

---

## Admin Endpoints

### GET /api/admin/users

List all users (admin only).

**Authentication:** Required (admin role)

**Response:** `200 OK`
```json
{
  "data": {
    "items": [
      {
        "id": "user_123",
        "email": "user@example.com",
        "roles": ["user"],
        "createdAt": "2025-01-01T00:00:00Z",
        "workoutCount": 42
      }
    ]
  }
}
```

---

### GET /api/admin/stats

System statistics (admin only).

**Authentication:** Required (admin role)

**Response:** `200 OK`
```json
{
  "data": {
    "totalUsers": 150,
    "totalWorkouts": 3420,
    "totalSets": 45600,
    "activeToday": 32
  }
}
```

---

### Error Responses

All errors follow the Google JSON Style Guide format:

```json
{
  "error": {
    "code": 400,
    "message": "Invalid input: weight must be a positive number",
    "errors": [
      {
        "domain": "workout",
        "reason": "invalidValue",
        "message": "Weight must be a positive number",
        "location": "exercises[0].sets[0].weight",
        "locationType": "field"
      }
    ]
  }
}
```

### Error Codes

- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - Insufficient permissions (e.g., not admin)
- `404 Not Found` - Resource doesn't exist
- `409 Conflict` - Resource conflict (e.g., duplicate)
- `500 Internal Server Error` - Server error

---

## Rate Limiting

- **Authenticated requests:** 1000 req/hour per user
- **Unauthenticated requests:** 100 req/hour per IP

---

## Pagination

List endpoints follow the Google JSON Style Guide pagination format.

**Query Parameters:**
- `limit` or `itemsPerPage`: Items per page (default: 50, max: 100)
- `offset` or `startIndex`: Starting index (default: 0)

**Example Request:**
```
GET /api/workouts?startIndex=20&itemsPerPage=10
```

Response includes pagination metadata:
```json
{
  "data": {
    "currentItemCount": 10,
    "itemsPerPage": 10,
    "startIndex": 20,
    "totalItems": 150,
    "items": [...]
  }
}
```

**Pagination Fields:**
- `currentItemCount`: Number of items in current response
- `itemsPerPage`: Max items per page (from request)
- `startIndex`: Zero-based index of first item
- `totalItems`: Total number of items across all pages
- `items`: Array of actual data items (always last property)

---

## Versioning

API is currently **v1** (no version prefix in URL).

Future versions will use: `/api/v2/...`

---

## CORS

Allowed origins (development):
- `http://localhost:3000`
- `http://localhost:3001`

Allowed origins (production):
- `https://thiccc.app`
- `https://www.thiccc.app`

---

## WebSockets (Future)

Planned for Phase 6 (Live Tracking):
- `ws://localhost:8000/api/workouts/:id/live`
- Real-time set updates during active workout

