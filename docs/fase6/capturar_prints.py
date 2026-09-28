"""Captura telas do dashboard Angular (API no perfil oracle) para a documentacao."""
import json, urllib.request
from playwright.sync_api import sync_playwright

API, WEB = "http://localhost:8080/api", "http://localhost:4200"
req = urllib.request.Request(f"{API}/auth/login", data=json.dumps({"username": "admin", "password": "1234"}).encode(),
                             headers={"Content-Type": "application/json"})
auth = json.load(urllib.request.urlopen(req))

with sync_playwright() as p:
    browser = p.chromium.launch(channel="chrome", headless=True)
    page = browser.new_page(viewport={"width": 1366, "height": 860}, device_scale_factor=1.5)
    page.goto(f"{WEB}/login")
    page.evaluate("([t,u]) => { localStorage.setItem('smarthas_token', t); localStorage.setItem('smarthas_user', u); }",
                  [auth["token"], json.dumps(auth["user"])])

    page.goto(f"{WEB}/home"); page.wait_for_selector(".data-table"); page.wait_for_timeout(600)
    page.screenshot(path="prints/01_home.png")

    page.goto(f"{WEB}/sensors/6"); page.wait_for_selector(".kpi-card"); page.wait_for_timeout(400)
    page.fill("#value", "91.3"); page.click(".reading-form button")
    page.wait_for_selector(".result"); page.wait_for_timeout(1200)
    page.screenshot(path="prints/02_sensor_detalhe.png", full_page=True, clip={"x": 0, "y": 0, "width": 1366, "height": 1180})

    page.goto(f"{WEB}/reports"); page.wait_for_selector(".data-table"); page.wait_for_timeout(500)
    page.click("text=Verificar sensores inativos"); page.wait_for_selector(".banner-success"); page.wait_for_timeout(900)
    page.screenshot(path="prints/03_relatorios.png", full_page=True)

    page.goto(f"{WEB}/admin"); page.wait_for_selector(".alert-item"); page.wait_for_timeout(500)
    page.screenshot(path="prints/04_admin_alertas.png")

    page.goto("http://localhost:8080/swagger-ui.html"); page.wait_for_selector("text=Telemetria"); page.wait_for_timeout(800)
    page.screenshot(path="prints/05_swagger.png")
    browser.close()
print("ok")
