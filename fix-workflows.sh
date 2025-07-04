#!/bin/bash

# Fix GitHub Actions workflow versions to resolve linter issues

echo "Fixing GitHub Actions workflow versions..."

# Fix azure/login@v1 to azure/login@v2
sed -i 's/azure\/login@v1/azure\/login@v2/g' .github/workflows/*.yml

# Fix any Azure/login (capital A) to azure/login
sed -i 's/Azure\/login@v[0-9]/azure\/login@v2/g' .github/workflows/*.yml

# Fix hashicorp/setup-terraform to use @v3 (already correct)
# Fix actions/checkout to use @v4 (already correct)
# Fix actions/upload-artifact to use @v4 (already correct)
# Fix actions/download-artifact to use @v4 (already correct)

echo "✅ Fixed workflow action versions"
echo "Changed azure/login@v1 to azure/login@v2 throughout workflows"

# Show what was changed
echo ""
echo "Checking for any remaining version issues..."
grep -n "azure/login" .github/workflows/*.yml || echo "No azure/login references found"
