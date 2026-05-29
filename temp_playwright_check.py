from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.on('console', lambda msg: print('CONSOLE', msg.type, msg.text))
    page.on('pageerror', lambda exc: print('PAGEERROR', exc))
    page.on('requestfailed', lambda req: print('REQFAILED', req.url, req.failure))
    page.goto('https://inventory-count-app-jao.web.app', timeout=60000)
    page.wait_for_load_state('networkidle', timeout=60000)
    page.wait_for_timeout(5000)
    print('URL', page.url)
    print('TITLE', page.title())
    print('CONTENT SNIPPET', page.content()[:1000])
    page.screenshot(path='temp_deploy_snapshot.png', full_page=True)
    browser.close()
