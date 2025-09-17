const { chromium } = require('playwright');

(async () => {
  const issue = process.argv[2]; // issue number from command line
  if (!issue) {
    console.error("Usage: node get_pdf_url.js <issue_number>");
    process.exit(1);
  }

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(`https://magazine.raspberrypi.com/issues/${issue}/pdf/download`, {
    waitUntil: 'networkidle'
  });

  // Find the first /downloads/...pdf link
  const link = await page.$eval('a[href*="/downloads/"][href$=".pdf"]', el => el.href)
    .catch(() => null);

  if (link) {
    console.log(link);
  }

  await browser.close();
})();
