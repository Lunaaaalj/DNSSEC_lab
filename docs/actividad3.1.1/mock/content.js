/* Shared slide copy (English). Every style prototype renders this same markup so the comparison is fair. */
document.getElementById('slides').innerHTML = `
<section class="slide s-cover" data-cam="full" data-phase="0" data-pad="0" data-notes="Open with the claim: the weakest link is a relationship, not a machine. The graph behind is a synthetic company; every edge is a trust relationship an attacker can borrow.">
  <div class="blk">
    <h1>Social engineering</h1>
    <p class="sub">Pentesting methods that attack the person, not the machine.</p>
    <p class="foot">Activity 3.1.1 · [Name] · [Course]</p>
  </div>
</section>

<section class="slide s-method" data-stepmode="phase" data-steps="5" data-pad="0.38" data-notes="Press → to walk the five phases. The camera follows the attack path through the same graph. Phase 5 shows where verification gates would have cut it.">
  <h2 class="hd">Five phases, one lever: trust</h2>
  <ol class="keys">
    <li data-lit="1"><b>1</b><span>Reconnaissance</span></li>
    <li data-lit="2"><b>2</b><span>Pretext</span></li>
    <li data-lit="3"><b>3</b><span>Contact</span></li>
    <li data-lit="4"><b>4</b><span>Exploitation</span></li>
    <li data-lit="5"><b>5</b><span>Report</span></li>
  </ol>
  <div class="caps">
    <p class="cap" data-only="1"><b>Reconnaissance</b>Open sources show who talks to whom: an org chart, a website, a conference photo. No system is touched.</p>
    <p class="cap" data-only="2"><b>Pretext</b>Borrow a role people already trust. Everyone has a reason to answer the IT Help Desk.</p>
    <p class="cap" data-only="3"><b>Contact</b>One message from the borrowed role reaches the target. The edge in the graph is the attack.</p>
    <p class="cap" data-only="4"><b>Exploitation</b>Authority plus urgency: the clerk enters credentials. The system worked as designed.</p>
    <p class="cap" data-only="5"><b>Report</b>Findings become verification gates on the edges that mattered, not blame for the person.</p>
  </div>
</section>

<section class="slide s-case" data-cam="contact" data-phase="3" data-steps="3" data-pad="0.44" data-notes="Synthetic scenario, authorized, fictional company. Step with → to highlight each indicator. Click rate is a placeholder until a real exercise is measured.">
  <h2 class="hd">Simulated case: the urgent password email</h2>
  <div class="mail">
    <p class="mh"><b>From</b> IT Help Desk &lt;helpdesk@<span class="hl" data-is="1">meridian-logistlcs.example</span>&gt;</p>
    <p class="mh"><b>To</b> Sam, Accounts Payable</p>
    <p class="mh"><b>Subject</b> <span class="hl" data-is="2">Action required: your password expires in 2 hours</span></p>
    <p class="mb">Hi Sam, your account password expires today at 17:00. To keep access, confirm it now.</p>
    <p class="mb"><span class="btn hl" data-is="3">Confirm password</span></p>
  </div>
  <div class="anns">
    <p class="ann" data-only="1"><b>Look-alike domain.</b> An “l” stands in for the “i”: the sender is not the real Help Desk.</p>
    <p class="ann" data-only="2"><b>Manufactured urgency.</b> A two-hour deadline leaves no time to verify.</p>
    <p class="ann" data-only="3"><b>Mismatched link.</b> The button leads to the look-alike host, not the company login.</p>
  </div>
  <p class="seal">Synthetic scenario · authorized · fictional company · results: [to be measured]</p>
</section>

<section class="slide s-defense" data-cam="full" data-phase="4" data-pad="0.38" data-notes="Toggle the verification and watch the same attack die at the edge. The point: defend the relationship (verify out of band), do not train people to be perfect.">
  <h2 class="hd">Defense: break the edge, not the person</h2>
  <button id="verify" aria-pressed="false" data-off="Out-of-band verification: OFF" data-on="Out-of-band verification: ON">Out-of-band verification: OFF</button>
  <p class="status v-off">Without a check, the Help Desk’s authority reaches Accounts Payable unchallenged. The account falls.</p>
  <p class="status v-on">The clerk hangs up and calls the Help Desk back on the number in the directory. The request dies at the edge.</p>
  <p class="seal">Press the button, or Tab to it and press Enter.</p>
</section>
`;
