# Performance Test Suite

This directory contains performance benchmarking tests for critical paths in the TTRPG Character Sheets application.

## Purpose

Performance tests help:
- **Detect Regressions:** Catch performance degradation before it reaches production
- **Establish Baselines:** Document expected performance characteristics
- **Guide Optimization:** Identify bottlenecks and measure improvements
- **Track Progress:** Monitor performance trends over time

## Test Categories

### 1. PDF Rendering Performance (`PDFRenderingPerformanceTests.swift`)

Tests PDF loading, rendering, and thumbnail generation performance.

**Key Metrics:**
- PDF document creation time
- Page rendering time (target: < 100ms for iPad resolution)
- Thumbnail generation (target: < 50ms per page)
- Multi-page navigation smoothness

**Baselines:**
- PDF loading (2-page sheet): < 100ms
- Page render (1024x1366): < 200ms
- Thumbnail (200x200): < 50ms

### 2. Drawing Save/Load Performance (`DrawingSaveLoadPerformanceTests.swift`)

Tests PencilKit drawing serialization and SwiftData persistence.

**Key Metrics:**
- PKDrawing serialization time
- PKDrawing deserialization time
- SwiftData save/load times
- Memory footprint for large drawings

**Baselines:**
- Drawing save (50 strokes): < 50ms
- Drawing load (50 strokes): < 30ms
- Large drawing (500 strokes): < 200ms
- Memory per drawing: < 5MB

### 3. Pagination Performance (`PaginationPerformanceTests.swift`)

Tests page navigation, state restoration, and transition animations.

**Key Metrics:**
- Page index update time
- Lazy page drawing creation
- State restoration speed
- Page transition preparation (60 FPS target)

**Baselines:**
- Page navigation: < 16ms (60 FPS)
- State restoration: < 100ms
- Transition prep: < 33ms

## Running Performance Tests

### Via Xcode

1. Open `TTRPGCharacterSheets.xcodeproj`
2. Select **Product → Test** or press `⌘U`
3. Or run specific test class:
   - Open Test Navigator (`⌘6`)
   - Right-click test class → **Run "ClassName"**

### Via Command Line

```bash
# Run all tests (including performance)
xcodebuild test \
  -scheme TTRPGCharacterSheets \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch),OS=17.0'

# Run only performance tests
xcodebuild test \
  -scheme TTRPGCharacterSheets \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch),OS=17.0' \
  -only-testing:TTRPGCharacterSheetsTests/PDFRenderingPerformanceTests \
  -only-testing:TTRPGCharacterSheetsTests/DrawingSaveLoadPerformanceTests \
  -only-testing:TTRPGCharacterSheetsTests/PaginationPerformanceTests
```

### In CI/CD

Performance tests run automatically on PRs via `.github/workflows/pr-quality.yml`.

## Interpreting Results

### Xcode Performance Metrics

Xcode displays performance test results with:
- **Average:** Mean execution time
- **Std Dev:** Standard deviation (consistency)
- **Min/Max:** Range of measurements
- **Baseline:** Previous run comparison (if set)

### Setting Baselines

1. Run tests on known-good commit
2. In Test Results, click test → **Set Baseline**
3. Future runs compare against this baseline
4. Yellow warning if > 10% regression
5. Red failure if > 20% regression (configurable)

### Example Output

```
Test Case '-[PDFRenderingPerformanceTests testPDFDocumentCreationPerformance]' measured [Time, seconds] average: 0.045, relative standard deviation: 5.234%, values: [0.043, 0.046, 0.044, 0.047, 0.045, 0.044, 0.046, 0.044, 0.045, 0.046]
✅ PASS - Within baseline (0.050s ± 10%)
```

## Adding New Performance Tests

### Structure

```swift
import XCTest
@testable import TTRPGCharacterSheets

@MainActor
final class MyPerformanceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        // Setup in-memory SwiftData container
    }

    override func tearDown() async throws {
        // Cleanup
    }

    func testFeaturePerformance() throws {
        measure {
            // Code to benchmark
        }
    }

    func testFeatureWithMetrics() throws {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Benchmark time AND memory
        }
    }
}
```

### Best Practices

1. **Realistic Data:** Use representative sample data (2-4 page PDFs, 50-100 stroke drawings)
2. **Isolation:** Each test should be independent
3. **Warmup:** XCTest automatically runs warmup iterations
4. **Consistency:** Run on same device/simulator for comparable results
5. **Document Baselines:** Comment expected performance in test

### Metrics Available

- **XCTClockMetric:** Wall clock time (default)
- **XCTMemoryMetric:** Peak memory usage
- **XCTCPUMetric:** CPU cycles consumed
- **XCTStorageMetric:** Disk I/O operations

### Example

```swift
func testLargeDrawingSavePerformance() throws {
    let drawing = createComplexDrawing(strokeCount: 500)

    // Measure both time and memory
    measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
        _ = drawing.dataRepresentation()
    }

    // Target: < 200ms, < 10MB peak memory
}
```

## Performance Targets

| Operation | Target | Critical Threshold |
|-----------|--------|-------------------|
| PDF Load (2 pages) | < 100ms | < 200ms |
| PDF Render (full page) | < 200ms | < 500ms |
| Drawing Save (50 strokes) | < 50ms | < 100ms |
| Drawing Load (50 strokes) | < 30ms | < 80ms |
| Page Navigation | < 16ms | < 33ms (30 FPS) |
| State Restoration | < 100ms | < 300ms |

**Rationale:**
- **60 FPS:** 16.67ms frame budget for animations
- **Perceived Instant:** < 100ms feels instant to users
- **Acceptable Wait:** < 300ms acceptable for complex operations

## Continuous Monitoring

### GitHub Actions Integration

The `.github/workflows/pr-quality.yml` workflow runs performance tests and:
- ✅ Passes if all tests complete
- ⚠️ Warns if > 10% slower than baseline
- ❌ Fails if > 20% slower than baseline (prevents merge)

### Performance Trends

Track performance over time by:
1. Export test results: `xcodebuild test ... | tee test-results.txt`
2. Parse metrics from output
3. Graph trends (future: integrate with performance dashboard)

## Troubleshooting

### Test Timeouts

If performance tests timeout (> 600s default):
```swift
func testSlowOperation() throws {
    // Extend timeout for this test
    executionTimeAllowance = 120 // 2 minutes
    measure { ... }
}
```

### Flaky Results

If results vary widely (> 20% std dev):
- Run on physical device (simulator varies with Mac load)
- Close other apps
- Disable animations: `UIView.setAnimationsEnabled(false)`
- Increase iteration count: `options.iterationCount = 20`

### Memory Leaks

Use Instruments for detailed profiling:
```bash
instruments -t Leaks -D leak-report.trace \
  -w "iPad Pro (12.9-inch)" \
  YourApp.app
```

## References

- [XCTest Performance Testing](https://developer.apple.com/documentation/xctest/performance_tests)
- [WWDC 2019: Testing in Xcode](https://developer.apple.com/videos/play/wwdc2019/413/)
- [Measuring Performance](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/PerformanceOverview/MeasuringPerformance/MeasuringPerformance.html)

---

**Last Updated:** 2026-01-04
**Maintained By:** Development Team
