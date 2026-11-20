/* Shared slide copy. Every terminal prototype renders this same markup; CSS adds each style's prompt and chrome. */
document.getElementById('slides').innerHTML = `
<section class="slide s-cover" data-scene="cover" data-cx=".73" data-notes="Open with the claim: the weakest link is a relationship, not a machine. The bust behind assembles from characters; the keyhole sits where trust lives.">
  <p class="cmd" data-type>whoami --activity 3.1.1</p>
  <h1>Social<br>engineering</h1>
  <p class="sub">Pentesting methods that attack the person, not the machine.</p>
  <p class="foot">[Name] · [Course] · Activity 3.1.1</p>
</section>

<section class="slide s-method" data-scenes="idle,recon,pretext,contact,exploit,report" data-steps="5" data-cx=".71" data-clip=".43" data-notes="Press → for each phase. Each phase has its own ASCII scene: radar sweep, forged badge, the message in flight, the key in the lock, the lock closing with the controls.">
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

<section class="slide s-case" data-scene="stream" data-steps="3" data-cx=".72" data-clip=".46" data-notes="Synthetic scenario, authorized, fictional company. Step with → to highlight each indicator. Click rate is a placeholder until a real exercise is measured.">
  <p class="cmd" data-type>cat case/phish-001.eml</p>
  <h2 class="hd">Case: urgent password email</h2>
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

<section class="slide s-defense" data-scene="defense" data-cx=".72" data-clip=".44" data-notes="Toggle the verification and watch the same message die at the wall. Defend the channel, do not train people to be perfect.">
  <p class="cmd" data-type>./defend --channel call-back</p>
  <h2 class="hd">Break the channel, not the person</h2>
  <button id="verify" aria-pressed="false" data-off="verification: OFF" data-on="verification: ON">verification: OFF</button>
  <p class="status v-off">Without a check, the Help Desk’s authority reaches Accounts Payable unchallenged. The lock opens.</p>
  <p class="status v-on">The clerk hangs up and calls the Help Desk back on the directory number. The message dies at the wall.</p>
</section>
`;
