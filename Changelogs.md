# Changelogs

## [v0.0.1] Package fix + Resize parts for visualization | 2025/10/22

Fixed package problems by turning the `SegmentedRoute` folder into a package module.

Added a new parameter `autoResizePartLength` to the visualizer, which resizes & repositions parts so they connect each sampled position.

Also, the `createParts` visualizer functions now return both the parts `Folder` and a `table` of created parts.

| Without `autoResizePartLength` | With `autoResizePartLength` |
|:---:|:---:|
| ![Bezier curve route with dots at equal distance](assets/images/visual-reparameterized.png) | ![Parts connected at the dots in the previous image](assets/images/visual-connected.png) |

## [v0.0.0] Segmented Route Project | 2025/10/21

Created Segmented Route with four parts.

Implemented `RouteSegmentBase` parent class and `BezierCurve` inherited class.

Implemented `ControlPoint` class.

Implemented `LinkedRoute` class.

Implemented `RouteUtil` class with `RouteReparam` for reparameterization and `RouteVisualizer` for simple visualization.

