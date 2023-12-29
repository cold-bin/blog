msg=$1

if [ -z "$msg" ]; then
    echo "commit msg empty"
    exit 0;
fi

echo "complie..."
hugo
echo "compile success..."

echo "upload..."
git add .
git commit -m "$msg"
git push -u origin main
echo "upload success..."

