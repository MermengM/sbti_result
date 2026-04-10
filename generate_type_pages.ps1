$root = 'c:\Projects\sbti_result'
$typesDir = Join-Path $root 'types'
$agnetPath = Join-Path $root 'agnet.md'
$agentPath = Join-Path $root 'agent.md'

New-Item -ItemType Directory -Path $typesDir -Force | Out-Null

if (-not (Test-Path $agnetPath)) {
  if (Test-Path $agentPath) {
    $agnetPath = $agentPath
  }
  else {
    throw 'Missing agnet.md or agent.md.'
  }
}

$libraryObj = Get-Content (Join-Path $root 'TYPE_LIBRARY.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$sourceLines = Get-Content $agnetPath -Encoding UTF8

function To-Slug([string]$code) {
  $slug = $code.ToLower()
  $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-')
  $slug = $slug.Trim('-')
  if ([string]::IsNullOrWhiteSpace($slug)) {
    return 'type'
  }
  return $slug
}

function Encode-Html([string]$text) {
  if ($null -eq $text) {
    return ''
  }
  return [System.Net.WebUtility]::HtmlEncode($text)
}

function Normalize-AnswerLine([string]$text) {
  if ([string]::IsNullOrWhiteSpace($text)) {
    return ''
  }
  return ($text.Trim() -replace '\s+', ' ')
}

function Get-AnswerValues([string]$answerLine) {
  if ([string]::IsNullOrWhiteSpace($answerLine)) {
    return @()
  }

  $parts = @($answerLine -split '\s+' | Where-Object { $_ })
  if ($parts.Count -ne 30) {
    return @()
  }

  foreach ($part in $parts) {
    if ($part -notmatch '^[1-3]$') {
      return @()
    }
  }

  return $parts
}

function U([string]$escaped) {
  return [regex]::Unescape($escaped)
}

$labelBack = U '\u8FD4\u56DE\u9996\u9875'
$labelDescription = U '\u4EBA\u683C\u7B80\u4ECB'
$labelPersonaCode = U '\u4EBA\u683C\u7801'
$labelSpecialNotes = U '\u7279\u6B8A\u8BF4\u660E'
$labelStable = U '30\u9898\u7A33\u5B9A\u76F4\u8FBE\uFF08\u4F18\u5148\u63A8\u8350\uFF09'
$labelMinimal = U '30\u9898\u6700\u5C11\u6863\u4F4D\uFF08\u7701\u5206\u7248\uFF09'
$labelTips = U '\u4F5C\u7B54\u63D0\u9192'
$labelStartAnswer = U '\u6309\u8FD9\u5957\u7B54\u6848\u5F00\u59CB\u7B54\u9898'
$labelNoFixedAnswer = U '\u8BE5\u65B9\u6848\u65E0\u56FA\u5B9A 30 \u9898\u7B54\u6848'

$defaultTipSteady = U '\u60F3\u7A33\uFF1A\u6309\u7A33\u5B9A\u76F4\u8FBE\u4F5C\u7B54\u3002'
$defaultTipSave = U '\u60F3\u7701\uFF1A\u6309\u6700\u5C11\u6863\u4F4D\u4F5C\u7B54\uFF0C\u4F46\u66F4\u5BB9\u6613\u8DD1\u504F\u5230\u76F8\u8FD1\u4EBA\u683C\u3002'
$defaultTipNoDrunk = U '\u4E0D\u60F3\u9152\u9B3C\uFF1A\u8865\u5145\u9898 drink_gate_q2 \u4E0D\u8981\u9009\u5206\u503C 2\u3002'

$drunkStableFallback = U '\u4E0D\u9002\u7528\uFF1A\u8BE5\u4EBA\u683C\u7531\u8865\u5145\u9898 drink_gate_q2 \u89E6\u53D1\uFF0C\u4E0D\u9760 30 \u9898\u56FA\u5B9A\u547D\u4E2D\u3002'
$hhhhStableFallback = U '\u4E0D\u9002\u7528\uFF1A\u8FD9\u662F\u5339\u914D\u5EA6\u8FC7\u4F4E\u65F6\u7684\u515C\u5E95\u4EBA\u683C\uFF0C\u65E0\u6CD5\u7ED9\u51FA\u56FA\u5B9A 30 \u9898\u5FC5\u4E2D\u7B54\u6848\u3002'
$hhhhMinimalFallback = U '\u4E0D\u9002\u7528\uFF1A\u82E5\u4E0D\u60F3\u89E6\u53D1\u8BE5\u4EBA\u683C\uFF0C\u4F18\u5148\u6309\u666E\u901A\u4EBA\u683C\u7684\u7A33\u5B9A\u76F4\u8FBE\u65B9\u6848\u4F5C\u7B54\u3002'

$quickLookup = @{}
$currentCode = $null
$headerPattern = '^###\s+([A-Za-z0-9!\-]+)\uFF08[^\uFF09]+\uFF09\s*$'
$bulletPattern = '^-\s*(.+)$'
$personaPattern = '([HML]{3}-[HML]{3}-[HML]{3}-[HML]{3}-[HML]{3})'

$tipQ = ''
$tipOrder = ''
$tipSteady = ''
$tipSave = ''
$tipNoDrunk = ''

foreach ($line in $sourceLines) {
  if ($line -match $bulletPattern) {
    $item = $matches[1].Trim()

    if (-not $tipQ -and $item -match 'q1' -and $item -match 'q30') {
      $tipQ = $item
    }

    if (-not $tipOrder -and $item -match 'A/B/C') {
      $tipOrder = $item
    }

    if (-not $tipSteady -and $item -match '^\u60F3\u7A33\uFF1A') {
      $tipSteady = $item
    }

    if (-not $tipSave -and $item -match '^\u60F3\u7701\uFF1A') {
      $tipSave = $item
    }

    if (-not $tipNoDrunk -and $item -match '^\u4E0D\u60F3\u9152\u9B3C\uFF1A') {
      $tipNoDrunk = $item
    }

  }

  if ($line -match '^##\s+') {
    $currentCode = $null
    continue
  }

  if ($line -match $headerPattern) {
    $currentCode = $matches[1].Trim()
    if (-not $quickLookup.ContainsKey($currentCode)) {
      $quickLookup[$currentCode] = [ordered]@{
        code = $currentCode
        personaCode = ''
        stable = ''
        minimal = ''
        notes = @()
      }
    }
    continue
  }

  if ([string]::IsNullOrWhiteSpace($currentCode)) {
    continue
  }

  if ($line -match $personaPattern) {
    $quickLookup[$currentCode].personaCode = $matches[1].Trim()
    continue
  }

  if ($line -match 'q1~q30' -and $line -match '[:\uFF1A]\s*(.+)$') {
    $answerLine = Normalize-AnswerLine $matches[1]
    if (-not $quickLookup[$currentCode].stable) {
      $quickLookup[$currentCode].stable = $answerLine
    }
    else {
      $quickLookup[$currentCode].minimal = $answerLine
    }
    continue
  }

  if (($currentCode -eq 'DRUNK' -or $currentCode -eq 'HHHH') -and $line -match $bulletPattern) {
    $note = $matches[1].Trim()
    if ($note -and $note -notmatch 'q1~q30') {
      $quickLookup[$currentCode].notes += $note
    }
  }
}

if (-not $tipQ) {
  $tipQ = 'Numbers run from q1 to q30 in order.'
}
if (-not $tipOrder) {
  $tipOrder = 'Pick by score value, not by A/B/C display order.'
}
if (-not $tipSteady) {
  $tipSteady = $defaultTipSteady
}
if (-not $tipSave) {
  $tipSave = $defaultTipSave
}
if (-not $tipNoDrunk) {
  $tipNoDrunk = $defaultTipNoDrunk
}

$profiles = @()
foreach ($prop in $libraryObj.PSObject.Properties) {
  $profiles += $prop.Value
}

foreach ($profile in $profiles) {
  $code = [string]$profile.code
  $cn = [string]$profile.cn
  $intro = [string]$profile.intro
  $desc = [string]$profile.desc
  $slug = To-Slug $code

  $lookup = $null
  if ($quickLookup.ContainsKey($code)) {
    $lookup = $quickLookup[$code]
  }

  $personaCode = ''
  $stableAnswer = ''
  $minimalAnswer = ''
  $specialNoteItems = @()

  if ($lookup) {
    $personaCode = [string]$lookup.personaCode
    $stableAnswer = [string]$lookup.stable
    $minimalAnswer = [string]$lookup.minimal
    $specialNoteItems = @($lookup.notes)
  }

  if ($code -eq 'DRUNK') {
    if (-not $stableAnswer) {
      $stableAnswer = $drunkStableFallback
    }
    if (-not $minimalAnswer) {
      $minimalAnswer = $tipNoDrunk
    }
  }

  if ($code -eq 'HHHH') {
    if (-not $stableAnswer) {
      $stableAnswer = $hhhhStableFallback
    }
    if (-not $minimalAnswer) {
      $minimalAnswer = $hhhhMinimalFallback
    }
  }

  if (-not $stableAnswer) {
    $stableAnswer = 'No fixed answer found. Please check source quick card.'
  }

  if (-not $minimalAnswer) {
    $minimalAnswer = 'No fixed answer found. Please check source quick card.'
  }

  $stableValues = @(Get-AnswerValues $stableAnswer)
  $minimalValues = @(Get-AnswerValues $minimalAnswer)

  $stableActionHtml = ''
  if ($stableValues.Count -eq 30) {
    $stableCsv = [string]::Join(',', $stableValues)
    $stableUrl = '../calculator.html?code=' + [uri]::EscapeDataString($code) + '&mode=stable&answers=' + [uri]::EscapeDataString($stableCsv)
    $stableActionHtml = '<a class="go-btn" href="' + $stableUrl + '">' + (Encode-Html $labelStartAnswer) + '</a>'
  }
  else {
    $stableActionHtml = '<span class="go-btn disabled">' + (Encode-Html $labelNoFixedAnswer) + '</span>'
  }

  $minimalActionHtml = ''
  if ($minimalValues.Count -eq 30) {
    $minimalCsv = [string]::Join(',', $minimalValues)
    $minimalUrl = '../calculator.html?code=' + [uri]::EscapeDataString($code) + '&mode=minimal&answers=' + [uri]::EscapeDataString($minimalCsv)
    $minimalActionHtml = '<a class="go-btn" href="' + $minimalUrl + '">' + (Encode-Html $labelStartAnswer) + '</a>'
  }
  else {
    $minimalActionHtml = '<span class="go-btn disabled">' + (Encode-Html $labelNoFixedAnswer) + '</span>'
  }

  $personaBlock = ''
  if ($personaCode) {
    $personaBlock = @"
    <section class="panel">
      <h2>$(Encode-Html $labelPersonaCode)</h2>
      <div class="badge">$(Encode-Html $personaCode)</div>
    </section>
"@
  }

  $specialNotesHtml = ''
  if ($specialNoteItems.Count -gt 0) {
    $noteItemsHtml = ''
    foreach ($note in $specialNoteItems) {
      $noteItemsHtml += "<li>$(Encode-Html ([string]$note))</li>`n"
    }

    $specialNotesHtml = @"
    <section class="panel">
      <h2>$(Encode-Html $labelSpecialNotes)</h2>
      <ul class="list">
        $noteItemsHtml      </ul>
    </section>
"@
  }

  $tipNoDrunkHtml = ''
  if ($code -eq 'DRUNK') {
    $tipNoDrunkHtml = "<li>$(Encode-Html $tipNoDrunk)</li>"
  }

  $html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$(Encode-Html $code) - $(Encode-Html $cn)</title>
  <style>
    :root {
      --bg-1: #0a1322;
      --bg-2: #11233a;
      --bg-3: #1b3557;
      --panel: rgba(255, 255, 255, 0.08);
      --line: rgba(255, 255, 255, 0.14);
      --title: #fff5de;
      --text: #deebff;
      --sub: #ffdca6;
      --accent: #f2a64e;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: "Noto Sans SC", "PingFang SC", "Microsoft YaHei", sans-serif;
      min-height: 100vh;
      color: var(--text);
      background:
        radial-gradient(circle at 8% 0%, rgba(244, 183, 91, 0.28), transparent 34%),
        radial-gradient(circle at 100% 10%, rgba(84, 175, 255, 0.24), transparent 32%),
        linear-gradient(145deg, var(--bg-1), var(--bg-2) 42%, var(--bg-3));
      padding: 22px 12px 40px;
    }

    .container {
      max-width: 900px;
      margin: 0 auto;
      display: grid;
      gap: 14px;
    }

    .back {
      color: #ffcf86;
      text-decoration: none;
      font-weight: 700;
      font-size: 14px;
      width: fit-content;
    }

    .panel {
      border: 1px solid var(--line);
      border-radius: 14px;
      background: var(--panel);
      padding: 16px;
    }

    .code {
      letter-spacing: 2px;
      font-size: 13px;
      color: var(--accent);
      margin-bottom: 6px;
      font-weight: 800;
    }

    h1 {
      font-size: clamp(28px, 7vw, 44px);
      margin-bottom: 8px;
      color: var(--title);
    }

    h2 {
      font-size: 18px;
      color: #ffe8bf;
      margin-bottom: 8px;
    }

    .intro {
      font-size: 15px;
      color: var(--sub);
      border-left: 3px solid var(--accent);
      padding-left: 10px;
      line-height: 1.8;
    }

    .desc {
      color: var(--text);
      line-height: 1.9;
      font-size: 14px;
      white-space: pre-wrap;
    }

    .badge {
      border: 1px solid rgba(255, 207, 134, 0.45);
      background: rgba(242, 166, 78, 0.16);
      border-radius: 10px;
      padding: 10px 12px;
      font-weight: 700;
      letter-spacing: 1px;
      font-size: 15px;
      color: #ffe1b2;
      word-break: break-word;
    }

    .answer-title {
      font-size: 12px;
      letter-spacing: 1px;
      color: #9fb6d6;
      margin-bottom: 8px;
      text-transform: uppercase;
    }

    .answers {
      border: 1px solid rgba(255, 255, 255, 0.14);
      border-radius: 10px;
      background: rgba(7, 15, 28, 0.52);
      padding: 10px 12px;
      color: #f2f7ff;
      line-height: 1.9;
      font-size: 14px;
      word-break: break-word;
    }

    .action-row {
      margin-top: 10px;
    }

    .go-btn {
      display: inline-block;
      border: 1px solid rgba(255, 220, 166, 0.5);
      background: linear-gradient(135deg, rgba(242, 166, 78, 0.24), rgba(255, 207, 134, 0.2));
      border-radius: 10px;
      padding: 8px 12px;
      font-size: 13px;
      font-weight: 700;
      color: #ffe8c2;
      text-decoration: none;
      cursor: pointer;
    }

    .go-btn:hover {
      filter: brightness(1.08);
    }

    .go-btn.disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .list {
      list-style: none;
      display: grid;
      gap: 8px;
      margin: 0;
      padding: 0;
    }

    .list li {
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 10px;
      background: rgba(0, 0, 0, 0.2);
      padding: 8px 10px;
      font-size: 13.5px;
      color: #dde8f5;
      line-height: 1.65;
    }

    @media (max-width: 760px) {
      body { padding: 16px 10px 28px; }
      .panel { padding: 14px; }
      .answers { font-size: 13px; }
    }
  </style>
</head>
<body>
  <main class="container">
    <a class="back" href="../index.html">$(Encode-Html $labelBack)</a>

    <section class="panel">
      <div class="code">$(Encode-Html $code)</div>
      <h1>$(Encode-Html $cn)</h1>
      <p class="intro">$(Encode-Html $intro)</p>
    </section>

    <section class="panel">
      <h2>$(Encode-Html $labelDescription)</h2>
      <div class="desc">$(Encode-Html $desc)</div>
    </section>
$personaBlock$specialNotesHtml    <section class="panel">
      <h2>$(Encode-Html $labelStable)</h2>
      <div class="answer-title">q1 ~ q30</div>
      <div class="answers">$(Encode-Html $stableAnswer)</div>
      <div class="action-row">$stableActionHtml</div>
    </section>

    <section class="panel">
      <h2>$(Encode-Html $labelMinimal)</h2>
      <div class="answer-title">q1 ~ q30</div>
      <div class="answers">$(Encode-Html $minimalAnswer)</div>
      <div class="action-row">$minimalActionHtml</div>
    </section>

    <section class="panel">
      <h2>$(Encode-Html $labelTips)</h2>
      <ul class="list">
        <li>$(Encode-Html $tipQ)</li>
        <li>$(Encode-Html $tipOrder)</li>
        <li>$(Encode-Html $tipSteady)</li>
        <li>$(Encode-Html $tipSave)</li>
        $tipNoDrunkHtml
      </ul>
    </section>
  </main>
</body>
</html>
"@

  $targetPath = Join-Path $typesDir ($slug + '.html')
  [System.IO.File]::WriteAllText($targetPath, $html, [System.Text.UTF8Encoding]::new($false))
}

Get-ChildItem $typesDir -Filter '*.html' | Select-Object -ExpandProperty Name
