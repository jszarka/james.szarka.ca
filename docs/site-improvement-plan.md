# james.szarka.ca — positioning and rebuild plan

Written 2026-09-23 alongside the AI-readability fixes in the same pull request.
This is the "what next" document: what the site is currently saying, what it should say,
and what to build it on.

---

## 1. What the site is right now

- **BreezyCV** (LMPixels, ThemeForest), template version 1.7.0 — a one-page résumé theme.
- jQuery 3.x plus Modernizr, Owl Carousel, Magnific Popup, Shuffle, Perfect Scrollbar,
  imagesLoaded, a validator, and the theme's own `main.js`: **11 scripts**, ~62 KB of HTML,
  FontAwesome 5.12 with four webfont formats including `.eot` (Internet Explorer 8).
- Sections: name + rotating job titles, About Me, What I Do, Testimonials, Clients,
  Fun Facts, Résumé, Portfolio, Contact.
- Four separate portfolio case-study pages, written recently and to a much higher standard.
- Deployed as an nginx container; Cloudflare in front, HTTP to origin.

The template is doing its job — it looks tidy. The problem is not the visual design, it's
what the page argues and how fast it argues it.

## 2. Marketing read

### The core problem: it reads like a résumé, and résumés are read only after someone is already interested

A hiring manager or a prospective client lands, gets a name, three job titles on a
carousel, and a wall of self-description. Nothing on the first screen tells them
**what happens when they hire you** or **what evidence backs it**. The strongest assets —
the four case studies with real dashboards, real Terraform, real recovery stories — are
buried behind a Portfolio tab most visitors will never click.

### Six specific problems

1. **The headline is a name, not a claim.** "James T. Szarka / DevOps Manager /
   Infrastructure On-Prem-Cloud Manager / SRE Manager" is three job titles rotating on a
   carousel. Job titles are what you *were called*; a claim is what you *do for them*.
2. **No numbers.** "Strategic Technical Leadership", "Site Reliability and Operational
   Resilience" — these could be on anyone's page. Uptime improved from what to what? MTTR?
   Cloud spend reduced by how much? Team size? Deploy frequency before and after? One real
   number beats a paragraph of adjectives, and it is also what an AI assistant can quote.
3. **"Fun Facts" actively costs you seniority.** "Awards Won Including childhood trophies"
   and "People I have talked to" are charming in person and undercutting in writing when the
   reader is deciding whether you can run a platform org. Cut it, or replace it with facts
   that support the case: years on call, largest environment run, incidents led.
4. **Testimonials are unattributed.** "Past Working Peer", "CISO Fintech" — anonymous praise
   reads as unverifiable. Named quotes with a company and a link (LinkedIn recommendations
   you already have) are worth ten anonymous ones. If a name can't be used, quote a specific
   outcome instead of an adjective.
5. **The portfolio pages are the best thing here and are hidden.** They score 93–100 on the
   PREFAB audit, they have evidence galleries, and they tell real stories. They should be on
   the home page as three cards above the résumé, not one tab down.
6. **One call to action, and it's "Download CV".** A PDF is a dead end. Decide what you want:
   an intro call, a consulting inquiry, or a recruiter conversation — and make that the
   primary action, with the PDF secondary.

### What to say instead

The site currently sells "experienced DevOps leader". The market has thousands. What is
actually differentiated here is the combination of **running platforms at work** and
**building and operating real infrastructure yourself** — a homelab with Proxmox, Terraform,
Grafana, Loki and Prometheus that produces the evidence in the case studies. Most engineering
leaders at your level stopped touching the keyboard years ago. That is the story.

A positioning line to work from — not final copy, a direction:

> **I make platforms boring.** Monitoring you trust, deployments nobody babysits, and cloud
> bills you can explain to finance. Twenty-five years of infrastructure, currently leading
> DevOps globally — and still building the thing to prove it works.

Then immediately, three proof cards linking the case studies, each with a one-line outcome.
Then the résumé. Then contact.

### Home page structure to aim for

| Position | Content | Purpose |
|---|---|---|
| Hero | Positioning line + one sentence + two CTAs ("Book a call", "Résumé PDF") | Answer "what do you do" in 5 seconds |
| Proof | 3 case-study cards with an outcome line each | Evidence before claims |
| Outcomes | 4–6 numbers: uptime, MTTR, spend reduced, team size, environments run | Make it quotable |
| How I work | The 4 "What I Do" blocks, rewritten as what the reader gets | Differentiate |
| Testimonials | 2–3 named quotes with company and role | Third-party credibility |
| Résumé | Experience, condensed, with the PDF | For the reader who is already sold |
| Contact | One form or one email, plus LinkedIn | Convert |

## 3. Technical direction

### The verdict on the current stack

The template is fine and is not worth fighting. Its cost is structural: heading levels are
used as visual styles (h4 for job titles, h5 for dates), which is why the audit reports
`h2 → h4` and `h3 → h5` skips, and why those can't be fixed without rewriting the theme CSS.
Eleven scripts to rotate three job titles and animate section transitions is a poor trade for
a page whose job is to be read fast, quoted by an assistant, and skimmed on a phone.

### Recommendation: Astro + Markdown content, no CMS

**Astro** ships zero JavaScript by default, renders everything to static HTML at build time
(exactly what AI crawlers need), supports Markdown/MDX for case studies, and has first-party
integrations for sitemaps, RSS and image optimization. The build output drops into the same
nginx container you already run, or onto Cloudflare Pages for free.

Why not the alternatives:

| Option | Verdict |
|---|---|
| **Astro** | **Recommended.** Static by default, component-based, Markdown content collections with typed frontmatter, trivial to deploy into the existing container. |
| Hugo (Go) | Also excellent and faster to build; single binary, no Node. Pick this if you prefer Go and no npm tree. Slightly more friction for component-style layouts. |
| Eleventy | Fine, lighter than Astro, less structure. Reasonable third choice. |
| Next.js / React | Overkill. You'd ship a framework runtime to render a résumé. |
| WordPress | No. A database, a plugin surface and a monthly patch cadence for a site that changes six times a year. It is the opposite of what you advise your own clients. |
| Decap / Sveltia CMS | Optional. Git-backed editing UI on top of Astro or Hugo if you ever want to edit from a phone. You are a git user; Markdown in an editor is faster. Add it only if the phone case becomes real. |

### Suggested stack

- **Astro** with **Tailwind** (or plain CSS — the site is small enough that a hand-written
  stylesheet under 300 lines is realistic and faster than a utility framework you have to learn).
- Case studies as **Markdown content collections**, so adding one is a file, not a page.
- `@astrojs/sitemap` for sitemap generation, and a small script to emit `llms.txt` from the
  same content collection so it can never drift from the site.
- Self-hosted fonts (drop FontAwesome's 4 formats; use inline SVG icons for the six icons
  actually used).
- Build in CI, publish the static output into the existing nginx image, keep the Docker
  deployment you already have.

Expect the page weight to drop by roughly an order of magnitude and the heading structure to
be correct by construction rather than by patching a purchased theme.

### Migration path (each step ships on its own)

1. **Now (this PR):** structural and AI-readability fixes on the existing template.
2. **Content first, before any rebuild:** write the positioning line, gather 4–6 real numbers,
   get two named testimonials, and write one-line outcomes for each case study. This is the
   work that actually moves the needle, and it is reusable whatever the stack.
3. **Rebuild the home page in Astro**, porting the four case studies as Markdown. Keep URLs
   identical (`/portfolio-observability-stack.html` etc.) or add redirects — those pages are
   already indexed and already score 93–100.
4. **Retire the template** once parity is reached.

## 4. Cloudflare settings that matter more than any of this

1. **AI Labyrinth / Bot Fight Mode is serving decoy pages on this domain.** The PREFAB crawl
   found `/cdn-cgi/content?id=…` URLs returning invented articles ("Volcanology: Unveiling the
   Secrets of Earth's Fiery Depths", "Meteorite Research"). That is Cloudflare feeding
   generated nonsense to something it classified as a bot. It did not happen on cloudplan.ca or
   backupplan.ca, so it is a per-zone setting on szarka.ca. **If the goal is to be found and
   quoted by AI assistants, this works directly against it** — an assistant crawling the site
   may index volcano articles instead of your CV. Decide deliberately: turn it off for this
   zone, or keep it and accept that AI assistants will not see this site correctly.
2. **`http://james.szarka.ca` returns 200 instead of redirecting.** Turn on
   SSL/TLS → Edge Certificates → **Always Use HTTPS**, and set the SSL mode to **Full (strict)**
   so Cloudflare talks to the origin over TLS rather than plain HTTP.
3. **Security headers** are set in the origin's 443 block, but Cloudflare reaches the origin on
   port 80, so browsers never see them. This PR adds them to the port 80 block as well; the
   durable fix is Full (strict) plus a Cloudflare Transform Rule for response headers.

## 5. Quick wins not in this PR

- Replace "Fun Facts" with an outcomes block.
- Get two testimonials attributed by name and company.
- Add a 1200×630 OpenGraph image (currently `main_photo.jpg`, a portrait crop, which social
  cards will letterbox).
- Put the three case-study cards on the home page above the résumé.
- Decide the single primary call to action and make everything else secondary.
