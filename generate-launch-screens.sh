#!/bin/bash

echo "🎨 开始生成启动屏所有尺寸..."

# iPhone 启动屏尺寸
declare -a sizes=(
    "1290x2796:iPhone15ProMax"
    "1179x2556:iPhone15Pro"
    "1170x2532:iPhone15"
    "1080x2340:iPhone14"
    "1284x2778:iPhone13ProMax"
    "1170x2532:iPhone13Pro"
    "1080x2340:iPhone13Mini"
    "1242x2688:iPhone11ProMax"
    "828x1792:iPhone11"
    "1125x2436:iPhoneX_XS"
    "750x1334:iPhoneSE"
)

for size_info in "${sizes[@]}"; do
    IFS=':' read -r size name <<< "$size_info"
    echo "生成 $name ($size)..."
    convert -background none -size "$size" launch-screen-with-props.svg "launch-screen-${name}-${size}.png"
done

echo ""
echo "✅ 所有尺寸生成完成！"
ls -lh launch-screen-*.png | tail -11
