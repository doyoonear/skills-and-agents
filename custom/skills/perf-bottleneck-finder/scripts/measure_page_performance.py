#!/usr/bin/env python3
"""
Page Performance Measurement Script

Playwright를 사용하여 웹 페이지의 성능을 자동으로 측정합니다.
Page Load, FCP, LCP, API TTFB, JS 실행 시간 등을 수집합니다.

Usage:
    python measure_page_performance.py --url "http://localhost:3000" --runs 3
    python measure_page_performance.py --url "http://localhost:3000/dashboard" --wait-for "[data-loaded]" --runs 5
    python measure_page_performance.py --url "http://localhost:3000" --output results.json

Options:
    --url           측정 대상 URL (필수)
    --runs          반복 측정 횟수 (기본값: 3)
    --output        결과 저장 파일 경로 (기본값: stdout)
    --wait-for      로딩 완료 판단 셀렉터 (기본값: networkidle 사용)
    --auth-cookie   인증 쿠키 (name=value 형식)
    --viewport      뷰포트 크기 (기본값: 1280x720)
    --help          도움말 표시
"""

import argparse
import json
import statistics
import sys
import time

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Error: playwright가 설치되어 있지 않습니다.")
    print("설치: pip install playwright && playwright install chromium")
    sys.exit(1)


PERFORMANCE_SCRIPT = """
() => {
    const nav = performance.getEntriesByType('navigation')[0];
    const paintEntries = performance.getEntriesByType('paint');
    const resources = performance.getEntriesByType('resource');

    const apiRequests = resources
        .filter(r => r.initiatorType === 'fetch' || r.initiatorType === 'xmlhttprequest')
        .map(r => ({
            url: r.name,
            name: new URL(r.name).pathname,
            method: 'GET',
            ttfb: Math.round(r.responseStart - r.requestStart),
            total: Math.round(r.responseEnd - r.startTime),
            size: r.transferSize || 0,
            encodedSize: r.encodedBodySize || 0,
            decodedSize: r.decodedBodySize || 0,
        }));

    const jsResources = resources
        .filter(r => r.initiatorType === 'script' || (r.name && r.name.endsWith('.js')))
        .map(r => ({
            url: r.name,
            name: new URL(r.name).pathname.split('/').pop(),
            loadTime: Math.round(r.responseEnd - r.startTime),
            size: r.transferSize || 0,
        }));

    const fcp = paintEntries.find(p => p.name === 'first-contentful-paint');

    return {
        navigation: {
            total: Math.round(nav.loadEventEnd - nav.startTime),
            domContentLoaded: Math.round(nav.domContentLoadedEventEnd - nav.startTime),
            domInteractive: Math.round(nav.domInteractive - nav.startTime),
            ttfb: Math.round(nav.responseStart - nav.requestStart),
            domComplete: Math.round(nav.domComplete - nav.startTime),
            redirect: Math.round(nav.redirectEnd - nav.redirectStart),
            dns: Math.round(nav.domainLookupEnd - nav.domainLookupStart),
            tcp: Math.round(nav.connectEnd - nav.connectStart),
            tls: nav.secureConnectionStart > 0
                ? Math.round(nav.connectEnd - nav.secureConnectionStart) : 0,
            transferSize: nav.transferSize || 0,
        },
        paint: {
            fcp: fcp ? Math.round(fcp.startTime) : null,
        },
        apiRequests,
        jsResources,
        resourceSummary: {
            totalRequests: resources.length,
            apiRequests: apiRequests.length,
            jsFiles: jsResources.length,
            totalTransferSize: resources.reduce((sum, r) => sum + (r.transferSize || 0), 0),
        },
    };
}
"""

LCP_SCRIPT = """
() => {
    return new Promise((resolve) => {
        let lcpValue = null;
        const observer = new PerformanceObserver((list) => {
            const entries = list.getEntries();
            if (entries.length > 0) {
                lcpValue = Math.round(entries[entries.length - 1].startTime);
            }
        });
        observer.observe({ type: 'largest-contentful-paint', buffered: true });

        setTimeout(() => {
            observer.disconnect();
            resolve(lcpValue);
        }, 500);
    });
}
"""

LONG_TASKS_SCRIPT = """
() => {
    return new Promise((resolve) => {
        const longTasks = [];
        const observer = new PerformanceObserver((list) => {
            list.getEntries().forEach(entry => {
                longTasks.push({
                    duration: Math.round(entry.duration),
                    startTime: Math.round(entry.startTime),
                });
            });
        });
        try {
            observer.observe({ type: 'longtask', buffered: true });
        } catch(e) {
            resolve([]);
            return;
        }
        setTimeout(() => {
            observer.disconnect();
            resolve(longTasks);
        }, 500);
    });
}
"""


def measure_once(page, url, wait_for_selector=None):
    """단일 측정 수행"""
    page.goto(url, wait_until="networkidle")

    if wait_for_selector:
        page.wait_for_selector(wait_for_selector, timeout=30000)

    time.sleep(1)

    perf_data = page.evaluate(PERFORMANCE_SCRIPT)
    lcp = page.evaluate(LCP_SCRIPT)
    long_tasks = page.evaluate(LONG_TASKS_SCRIPT)

    perf_data["paint"]["lcp"] = lcp
    perf_data["longTasks"] = long_tasks
    perf_data["longTasksSummary"] = {
        "count": len(long_tasks),
        "totalBlockingTime": sum(
            max(0, t["duration"] - 50) for t in long_tasks
        ),
    }

    console_errors = []
    page.on("console", lambda msg: console_errors.append(msg.text) if msg.type == "error" else None)

    return perf_data


def aggregate_results(runs_data):
    """여러 측정 결과를 집계"""
    result = {
        "navigation": {},
        "paint": {},
        "longTasksSummary": {},
        "apiRequests": {},
    }

    nav_keys = runs_data[0]["navigation"].keys()
    for key in nav_keys:
        values = [r["navigation"][key] for r in runs_data]
        result["navigation"][key] = {
            "avg": round(statistics.mean(values), 1),
            "min": min(values),
            "max": max(values),
            "stdev": round(statistics.stdev(values), 1) if len(values) > 1 else 0,
        }

    for paint_key in ["fcp", "lcp"]:
        values = [r["paint"][paint_key] for r in runs_data if r["paint"].get(paint_key) is not None]
        if values:
            result["paint"][paint_key] = {
                "avg": round(statistics.mean(values), 1),
                "min": min(values),
                "max": max(values),
            }

    tbt_values = [r["longTasksSummary"]["totalBlockingTime"] for r in runs_data]
    result["longTasksSummary"] = {
        "avgTotalBlockingTime": round(statistics.mean(tbt_values), 1),
        "avgLongTaskCount": round(statistics.mean([r["longTasksSummary"]["count"] for r in runs_data]), 1),
    }

    all_api_urls = set()
    for r in runs_data:
        for api in r["apiRequests"]:
            all_api_urls.add(api["name"])

    api_agg = []
    for api_name in sorted(all_api_urls):
        ttfbs = []
        totals = []
        sizes = []
        for r in runs_data:
            for api in r["apiRequests"]:
                if api["name"] == api_name:
                    ttfbs.append(api["ttfb"])
                    totals.append(api["total"])
                    sizes.append(api["size"])

        if ttfbs:
            api_agg.append({
                "name": api_name,
                "ttfb_avg": round(statistics.mean(ttfbs), 1),
                "total_avg": round(statistics.mean(totals), 1),
                "size_avg": round(statistics.mean(sizes)),
            })

    api_agg.sort(key=lambda x: x["total_avg"], reverse=True)
    result["apiRequests"] = api_agg
    result["resourceSummary"] = runs_data[0]["resourceSummary"]

    return result


def format_report(agg, url, runs_count):
    """보고서 포맷"""
    lines = []
    lines.append("=" * 60)
    lines.append("  Performance Measurement Report")
    lines.append("=" * 60)
    lines.append(f"  URL: {url}")
    lines.append(f"  Runs: {runs_count}")
    lines.append(f"  Date: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("-" * 60)

    lines.append("\n[ Page Load Timing ]")
    nav = agg["navigation"]
    timing_items = [
        ("TTFB", "ttfb"),
        ("DOM Interactive", "domInteractive"),
        ("DOM Content Loaded", "domContentLoaded"),
        ("DOM Complete", "domComplete"),
        ("Page Load (total)", "total"),
    ]
    for label, key in timing_items:
        if key in nav:
            d = nav[key]
            lines.append(f"  {label:<25} {d['avg']:>8.0f}ms  (min:{d['min']} max:{d['max']})")

    lines.append("\n[ Paint Timing ]")
    paint = agg["paint"]
    if "fcp" in paint:
        lines.append(f"  {'FCP':<25} {paint['fcp']['avg']:>8.0f}ms")
    if "lcp" in paint:
        lines.append(f"  {'LCP':<25} {paint['lcp']['avg']:>8.0f}ms")

    lines.append("\n[ Long Tasks ]")
    lt = agg["longTasksSummary"]
    lines.append(f"  {'Total Blocking Time':<25} {lt['avgTotalBlockingTime']:>8.0f}ms")
    lines.append(f"  {'Long Task Count':<25} {lt['avgLongTaskCount']:>8.0f}")

    if agg["apiRequests"]:
        lines.append("\n[ API Requests (sorted by total time) ]")
        lines.append(f"  {'Endpoint':<35} {'TTFB':>8} {'Total':>8} {'Size':>10}")
        lines.append("  " + "-" * 65)
        for api in agg["apiRequests"]:
            size_str = f"{api['size_avg'] / 1024:.1f}KB" if api["size_avg"] > 0 else "N/A"
            lines.append(
                f"  {api['name']:<35} {api['ttfb_avg']:>7.0f}ms {api['total_avg']:>7.0f}ms {size_str:>10}"
            )

    lines.append("\n[ Resource Summary ]")
    rs = agg["resourceSummary"]
    lines.append(f"  {'Total Requests':<25} {rs['totalRequests']:>8}")
    lines.append(f"  {'API Requests':<25} {rs['apiRequests']:>8}")
    lines.append(f"  {'JS Files':<25} {rs['jsFiles']:>8}")
    lines.append(f"  {'Total Transfer Size':<25} {rs['totalTransferSize'] / 1024:>7.1f}KB")

    total_ms = nav["total"]["avg"]
    lines.append("\n[ Bottleneck Analysis ]")
    segments = []
    if agg["apiRequests"]:
        api_total = sum(a["total_avg"] for a in agg["apiRequests"])
        segments.append(("API Requests", api_total))
    if "fcp" in paint:
        segments.append(("First Paint", paint["fcp"]["avg"]))
    if lt["avgTotalBlockingTime"] > 0:
        segments.append(("JS Blocking", lt["avgTotalBlockingTime"]))

    segments.sort(key=lambda x: x[1], reverse=True)
    for name, ms in segments:
        pct = (ms / total_ms * 100) if total_ms > 0 else 0
        bar = "#" * int(pct / 2)
        lines.append(f"  {name:<25} {ms:>7.0f}ms  {pct:>5.1f}%  {bar}")

    lines.append("\n" + "=" * 60)
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Measure web page performance using Playwright"
    )
    parser.add_argument("--url", required=True, help="Target URL to measure")
    parser.add_argument("--runs", type=int, default=3, help="Number of measurement runs (default: 3)")
    parser.add_argument("--output", help="Output file path (default: stdout)")
    parser.add_argument("--wait-for", help="CSS selector to wait for before measuring")
    parser.add_argument("--auth-cookie", help="Auth cookie in name=value format")
    parser.add_argument("--viewport", default="1280x720", help="Viewport size (default: 1280x720)")
    parser.add_argument("--json", action="store_true", help="Output raw JSON data")

    args = parser.parse_args()

    width, height = map(int, args.viewport.split("x"))

    print(f"Measuring {args.url} ({args.runs} runs)...\n")

    runs_data = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": width, "height": height})

        if args.auth_cookie:
            name, value = args.auth_cookie.split("=", 1)
            from urllib.parse import urlparse
            domain = urlparse(args.url).hostname
            context.add_cookies([{"name": name, "value": value, "domain": domain, "path": "/"}])

        for i in range(args.runs):
            page = context.new_page()
            print(f"  Run {i + 1}/{args.runs}...", end=" ")

            try:
                data = measure_once(page, args.url, args.wait_for)
                runs_data.append(data)
                total = data["navigation"]["total"]
                print(f"done ({total}ms)")
            except Exception as e:
                print(f"failed: {e}")
            finally:
                page.close()

        browser.close()

    if not runs_data:
        print("\nError: 모든 측정이 실패했습니다.")
        sys.exit(1)

    print()

    agg = aggregate_results(runs_data)

    if args.json:
        output = json.dumps(agg, indent=2, ensure_ascii=False)
    else:
        output = format_report(agg, args.url, len(runs_data))

    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"Results saved to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
