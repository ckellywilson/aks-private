#!/bin/bash

# Fix GitHub Actions workflow versions to resolve linter issues

echo "Fixing GitHub Actions workflow versions..."

# Fix azure/login to use the latest stable version
# Using @v2.3.0 (specific latest stable version)
sed -i 's/azure\/login@v1/azure\/login@v2.3.0/g' .github/workflows/*.yml
sed -i 's/azure\/login@v2[^.]/azure\/login@v2.3.0/g' .github/workflows/*.yml
sed -i 's/azure\/login@v2$/azure\/login@v2.3.0/g' .github/workflows/*.yml

# Fix any Azure/login (capital A) to azure/login
sed -i 's/Azure\/login@v[0-9]/azure\/login@v2/g' .github/workflows/*.yml

# Ensure all other actions are using latest versions
sed -i 's/actions\/checkout@v[0-9]/actions\/checkout@v4/g' .github/workflows/*.yml
sed -i 's/hashicorp\/setup-terraform@v[0-9]/hashicorp\/setup-terraform@v3/g' .github/workflows/*.yml
sed -i 's/actions\/upload-artifact@v[0-9]/actions\/upload-artifact@v4/g' .github/workflows/*.yml
sed -i 's/actions\/download-artifact@v[0-9]/actions\/download-artifact@v4/g' .github/workflows/*.yml

echo "✅ Fixed workflow action versions"
echo "Updated to latest stable versions:"
echo "  - azure/login@v2 (latest stable)"
echo "  - actions/checkout@v4"
echo "  - hashicorp/setup-terraform@v3" 
echo "  - actions/upload-artifact@v4"
echo "  - actions/download-artifact@v4"

# Show what was changed
echo ""
echo "Checking current action versions in workflows..."
echo "Azure login actions:"
grep -n "azure/login" .github/workflows/*.yml || echo "No azure/login references found"
echo ""
echo "Other actions:"
grep -n "uses: " .github/workflows/*.yml | grep -E "(checkout|setup-terraform|upload-artifact|download-artifact)" | head -5
