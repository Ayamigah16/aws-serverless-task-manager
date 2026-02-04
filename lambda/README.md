# Lambda Directory Structure

## Clean Structure (No Redundancy)

```
lambda/
├── layers/
│   ├── shared-layer/          # Source for layer
│   │   └── nodejs/            # Layer runtime files
│   │       ├── auth.js
│   │       ├── dynamodb.js
│   │       ├── eventbridge.js
│   │       ├── response.js
│   │       └── package.json
│   └── shared-layer.zip       # Packaged layer for deployment
├── notification-handler/
│   ├── index.js               # Uses /opt/nodejs/* from layer
│   ├── package.json
│   └── function.zip
├── pre-signup-trigger/
│   ├── index.js               # Standalone (no layer needed)
│   ├── package.json
│   └── function.zip
└── task-api/
    ├── index.js               # Uses /opt/nodejs/* from layer
    ├── package.json
    └── function.zip
```

## Import Paths

**Lambda functions using layer:**
```javascript
// task-api/index.js
const { validateRequest, isAdmin, getUserId } = require('/opt/nodejs/auth');
const { getItem, putItem, updateItem, query } = require('/opt/nodejs/dynamodb');
const { publishEvent } = require('/opt/nodejs/eventbridge');
const { success, error, unauthorized } = require('/opt/nodejs/response');

// notification-handler/index.js
const { getItem, query } = require('/opt/nodejs/dynamodb');
```

**Standalone function:**
```javascript
// pre-signup-trigger/index.js
// No shared dependencies
```

## Build Process

```bash
# Build all (layer + functions)
./scripts/build-lambdas.sh

# Build layer only
./scripts/build-layer.sh
```

## Redundancy Eliminated

**Before:**
- `lambda/shared/` directory (duplicated)
- Functions bundled shared code in zip
- Total: ~15KB per function

**After:**
- Single `lambda/layers/shared-layer/` directory
- Functions use layer at runtime
- Total: ~3KB layer + ~1KB per function

**Savings:** ~12KB per function, cleaner structure, single source of truth
