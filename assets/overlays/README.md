# Body Silhouette Overlay Assets

## Overview
This directory contains overlay assets for the C2.1 Camera Overlay Guidance feature.

**Current Implementation**: The app uses CustomPainter to draw silhouettes programmatically for optimal performance and flexibility.

## Asset Specifications (Optional Enhancement)

If you want to replace the CustomPaint silhouettes with image assets:

### Front Pose Silhouette (`body_front.png`)
- **Dimensions**: 400x700px (transparent PNG)
- **Content**: Full human outline from shoulders to feet
- **Privacy-safe**: Head can be simple circle or cropped at neck level
- **Style**: Subtle white outline (#FFFFFF @ 25% opacity)
- **Guide lines**: Horizontal dashed lines at:
  - 15% height (shoulders)
  - 45% height (hips)
  - 70% height (knees)
  - 95% height (feet)

### Side Pose Silhouette (`body_side.png`)
- **Dimensions**: 400x700px (transparent PNG)
- **Content**: Side profile outline (90° turn) from shoulders to feet
- **Privacy-safe**: Head can be simple circle or cropped
- **Style**: Same as front pose
- **Guide lines**: Same horizontal levels as front

## Color Scheme
- **Default State**: White @ 25% opacity (#FFFFFF40)
- **Ready State**: Green @ 30% opacity (#00FF0040)
- **Background**: Transparent

## Technical Notes
- Files should be optimized for mobile (keep under 50KB each)
- Use PNG format with alpha channel transparency
- Assets are loaded via pubspec.yaml: `assets/overlays/`
