/* Deck copy — Activity 3.1.1: social engineering in pentesting, built around the Social-Engineer Toolkit (SET).
   Every scenario is synthetic and authorized. The Mercedes-Benz item is a reported industry practice, labelled as such.
   The company "Meridian Logistics", the people, domains and numbers are invented for the exercise. */
document.getElementById('slides').innerHTML = `
<section class="slide s-cover" data-scene="cover" data-cx=".73" data-notes="Open with the claim: the weakest link is a relationship, not a machine. The bust behind assembles from characters; the keyhole sits where trust lives.">
  <p class="cmd" data-type>whoami --activity 3.1.1</p>
  <h1>Social<br>engineering<br>toolkit</h1>
  <p class="sub">Pentesting methods that attack the person, not the machine.</p>
  <ul class="team" aria-label="Team">
    <li><span>Montserrat Rodríguez Ramírez</span><i>A01661271</i></li>
    <li><span>Jannette Cristina Flores Rodríguez</span><i>A01255711</i></li>
    <li><span>Angel Eduardo Luna</span><i>A00842657</i></li>
    <li><span>Carolina Sarahí Sánchez Meneses</span><i>A00227980</i></li>
    <li><span>Elías Alejandro Corral Rodríguez</span><i>A01743624</i></li>
  </ul>
  <p class="foot"><span>Applications of Cryptography and Cybersecurity</span>Prof. Mohd Anas Wajid · Tecnológico de Monterrey · Activity 3.1.1</p>
</section>

<section class="slide s-method" data-scenes="idle,recon,pretext,contact,exploit,report" data-steps="5" data-cx=".71" data-clip=".44" data-notes="Press → for each phase. Each phase runs its own scene: radar sweep over open sources, a forged badge decoding, the message in flight, the key in the lock, the lock closing with the controls.">
  <p class="cmd" data-type>./phases --walk</p>
  <h2 class="hd">Five phases, one lever: trust</h2>
  <ol class="keys">
    <li data-lit="1" data-is="1"><b>1</b><span>Reconnaissance</span></li>
    <li data-lit="2" data-is="2"><b>2</b><span>Pretext</span></li>
    <li data-lit="3" data-is="3"><b>3</b><span>Contact</span></li>
    <li data-lit="4" data-is="4"><b>4</b><span>Exploitation</span></li>
    <li data-lit="5" data-is="5"><b>5</b><span>Report</span></li>
  </ol>
  <div class="caps">
    <p class="cap" data-only="0">Press → to run the first phase.</p>
    <p class="cap" data-only="1">Open sources show who talks to whom: an org chart, a website, a conference photo. No system is touched.</p>
    <p class="cap" data-only="2">Borrow a role people already trust. Everyone answers the IT Help Desk.</p>
    <p class="cap" data-only="3">One message from the borrowed role reaches the target: email, phone call, or a visit.</p>
    <p class="cap" data-only="4">Authority plus urgency: the clerk hands over the credentials. The system worked as designed.</p>
    <p class="cap" data-only="5">Findings become controls, not blame: call-back verification, MFA, a one-click report button.</p>
  </div>
</section>

<section class="slide s-tool" data-scene="exploit" data-cx=".72" data-clip=".44" data-notes="SET = Social-Engineer Toolkit. Open-source, ships with Kali. It automates human-facing tests so a red team can measure how people respond, then train them. It does not exploit software; it rehearses a believable trap.">
  <p class="cmd" data-type>man set-toolkit</p>
  <h2 class="hd">The tool: Social-Engineer Toolkit</h2>
  <p class="lede">Open-source framework bundled with Kali Linux. It automates <b>human-based</b> tests — phishing, cloned login pages — so teams can measure how people respond, then train them.</p>
  <ul class="facts">
    <li><b>Targets people, not software flaws</b> — it deceives a user into granting access or running a file.</li>
    <li><b>Menu-driven:</b> the operator picks a vector and customizes a believable trap.</li>
    <li><b>For authorized work:</b> red-team engagements and security-awareness programs.</li>
  </ul>
</section>

<section class="slide s-vectors" data-scene="pretext" data-steps="4" data-cx=".74" data-clip=".44" data-notes="SET's four main vectors. Walk them with →. Keep each one at the level of what it tests, not how to operate it — this is a methods overview, not a run-book.">
  <p class="cmd" data-type>set &gt; attack vectors</p>
  <h2 class="hd">Four attack vectors</h2>
  <ol class="rows">
    <li data-lit="1"><b>01</b><div><strong>Spear phishing</strong><span>Targeted fake emails with malicious attachments, aimed at specific people.</span></div></li>
    <li data-lit="2"><b>02</b><div><strong>Website / credential harvester</strong><span>Clones a real login page to capture what a user types when they “sign in”.</span></div></li>
    <li data-lit="3"><b>03</b><div><strong>Infectious media</strong><span>A payload left on a USB drive that runs when a curious person plugs it in.</span></div></li>
    <li data-lit="4"><b>04</b><div><strong>Mass mailer / SMS spoofing</strong><span>Bulk messages that test how a whole organization reacts to urgent notices.</span></div></li>
  </ol>
</section>

<section class="slide s-case" data-scene="phish" data-steps="3" data-cx=".72" data-clip=".44" data-notes="Synthetic scenario, authorized, fictional company. This is the credential-harvester vector seen from the inbox. Step with → to flag each indicator. Click rate is a placeholder until a real exercise is measured.">
  <p class="cmd" data-type>cat case/phish-001.eml</p>
  <h2 class="hd">Case: the urgent password email</h2>
  <div class="mail">
    <p class="mh"><b>From:</b> IT Help Desk &lt;helpdesk@<span class="hl" data-is="1">meridian-logistlcs.example</span>&gt;</p>
    <p class="mh"><b>To:</b> Sam, Accounts Payable</p>
    <p class="mh"><b>Subject:</b> <span class="hl" data-is="2">Action required: your password expires in 2 hours</span></p>
    <p class="mb">Hi Sam, your account password expires today at 17:00. To keep access, confirm it now.</p>
    <p class="mb"><span class="btn hl" data-is="3">Confirm password</span></p>
  </div>
  <div class="anns">
    <p class="ann" data-only="0">Press → to flag each indicator.</p>
    <p class="ann" data-only="1"><b>Look-alike domain.</b> An “l” stands in for the “i”: the sender is not the real Help Desk.</p>
    <p class="ann" data-only="2"><b>Manufactured urgency.</b> A two-hour deadline leaves no time to verify.</p>
    <p class="ann" data-only="3"><b>Mismatched link.</b> The button leads to the look-alike host, not the company login.</p>
  </div>
  <p class="seal">synthetic scenario · authorized · fictional company · results: [to be measured]</p>
</section>

<section class="slide s-real" data-scene="contact" data-cx=".87" data-clip=".6" data-notes="Left: a reported industry practice — an internal phishing drill (Mercedes-Benz is cited as an example; treat as reported, not verified here). Right: how SET reproduces the same drill with its credential-harvester module. Same goal: test and train before a real attacker arrives.">
  <p class="cmd" data-type>diff drill.real set.harvester</p>
  <h2 class="hd">One goal, two sides</h2>
  <div class="cols">
    <div class="col">
      <p class="col-h">Reported practice<span>internal phishing drill</span></p>
      <ol class="mini">
        <li>IT sends an email built to look real.</li>
        <li>Employee clicks, enters credentials on a fake login page.</li>
        <li>The account is locked automatically.</li>
        <li>Employee is sent to training on spotting fakes.</li>
      </ol>
      <p class="col-f">e.g. Mercedes-Benz · reported</p>
    </div>
    <div class="col">
      <p class="col-h">How SET does it<span>credential-harvester module</span></p>
      <ol class="mini">
        <li>Clone a real login page with Site Cloner.</li>
        <li>Host the clone; send the link in a spear-phish.</li>
        <li>Victim enters credentials, thinking it is real.</li>
        <li>SET records them — a pentest would use test accounts.</li>
      </ol>
      <p class="col-f">goal: do staff fall for it?</p>
    </div>
  </div>
  <p class="seal">authorized exercise · test accounts, never real credentials</p>
</section>

<section class="slide s-defense" data-scene="defense" data-cx=".72" data-clip=".44" data-notes="Toggle verification and watch the same message die at the wall. Defend the channel — verify out of band — rather than training people to be perfect.">
  <p class="cmd" data-type>./defend --channel call-back</p>
  <h2 class="hd">Break the channel, not the person</h2>
  <button id="verify" aria-pressed="false" data-off="verification: OFF" data-on="verification: ON">verification: OFF</button>
  <p class="status v-off">Without a check, the Help Desk’s authority reaches Accounts Payable unchallenged. The lock opens.</p>
  <p class="status v-on">The clerk hangs up and calls the Help Desk back on the directory number. The message dies at the wall.</p>
</section>

<section class="slide s-ethics" data-scene="report" data-cx=".72" data-clip=".44" data-notes="Close on the boundary that makes all of this legitimate. Social-engineering tests are only ethical with written permission, a defined scope, and synthetic targets. Findings train people; they never blame them.">
  <p class="cmd" data-type>cat RULES_OF_ENGAGEMENT</p>
  <h2 class="hd">Only ever with permission</h2>
  <ul class="rules">
    <li><b>Written authorization</b> and a scope agreed in advance.</li>
    <li><b>Controlled environment:</b> test accounts, never real credentials.</li>
    <li><b>Synthetic targets and data</b> — no real person is harmed.</li>
    <li><b>Findings become training,</b> not blame for whoever clicked.</li>
  </ul>
  <p class="seal">unauthorized social engineering is a crime, not a test</p>
</section>

<section class="slide s-refs" data-scene="idle" data-cx=".86" data-clip=".66" data-notes="References slide. Leave it up during questions. Links are clickable when presenting from the browser.">
  <p class="cmd" data-type>cat REFERENCES</p>
  <h2 class="hd">References</h2>
  <ol class="refs">
    <li>TrustedSec. (n.d.). <i>The Social-Engineer Toolkit (SET)</i> [Computer software]. GitHub. <a href="https://github.com/trustedsec/social-engineer-toolkit" target="_blank" rel="noopener">https://github.com/trustedsec/social-engineer-toolkit</a></li>
    <li>TrustedSec. (n.d.). <i>TrustedSec official website</i>. <a href="https://www.trustedsec.com/" target="_blank" rel="noopener">https://www.trustedsec.com/</a></li>
    <li>National Institute of Standards and Technology. (2008). <i>Technical guide to information security testing and assessment</i> (NIST Special Publication 800-115). <a href="https://csrc.nist.gov/pubs/sp/800/115/final" target="_blank" rel="noopener">https://csrc.nist.gov/pubs/sp/800/115/final</a></li>
  </ol>
</section>
`;
