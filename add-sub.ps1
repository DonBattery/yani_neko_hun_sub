
param(
    [Parameter(Position = 0)]
    [ValidateRange(1, 12)]
    [int]$EpisodeNumber
)

# English episode titles (source video filenames)
$EnglishTitles = @(
    "Chainsmoker.Cat.S01E01.Episode.1.1080p.NF.WEB-DL.AAC2.0.H.264-Kitsune",
    "Chainsmoker.Cat.S01E02.Episode.2.1080p.NF.WEB-DL.AAC2.0.H.264-Kitsune",
    "Chainsmoker.Cat.S01E03.Episode.3.1080p.NF.WEB-DL.AAC2.0.H.264-Kitsune",
    "Chainsmoker.Cat.S01E04.Episode.4.1080p.NF.WEB-DL.AAC2.0.H.264-Kitsune",
    "Chainsmoker.Cat.S01E05.Episode.5.1080p.NF.WEB-DL.AAC2.0.H.264-Kitsune",
    "Chainsmoker.Cat.S01E06.Episode.6.1080p.NF.WEB-DL.AAC2.0.H.264-Kitsune",
    "Chainsmoker.Cat.S01E07.Episode.7.1080p.NF.WEB-DL.AAC2.0.H.264-Kitsune",
    "Chainsmoker.Cat.S01E10.1080p.NF.WEB-DL.JPN.AAC2.0.H.264.MSubs-ToonsHub",
    "Chainsmoker Cat S01E08 1080p NF WEB-DL AAC2 0 H 264-VARYG",
    "Chainsmoker Cat S01E09 1080p NF WEB-DL AAC2 0 H 264-VARYG",
    "Chainsmoker.Cat.S01E11.1080p.NF.WEB-DL.JPN.AAC2.0.H.264.MSubs-ToonsHub",
    "Chainsmoker.Cat.S01E12.1080p.NF.WEB-DL.AAC2.0.H.264-VARYG"
)

# Hungarian episode titles (subtitle and output filenames)
$HungarianTitles = @(
    "ep01 - Láncdohányos macska vagyok Nyá",
    "ep02 - Bemutatom alcicáimat Nyá",
    "ep03 - Inkább józan vagyok mint vicces Nyá",
    "ep04 - Fura alakok körös körülöttem Nyá",
    "ep05 - Egy titkos helyre megyünk Nyá",
    "ep06 - Itt kezdődik a nyaram és itt is ér véget Nyá",
    "ep07 - Én is szülőktől származom Nyá",
    "ep08 - Decemberben még mi is körbe futkosunk Nyá",
    "ep09 - Hugi igen népszerű a hölgyek körében Nyá",
    "ep10 - Én is élvezni fogom az eseményt Nyá",
    "ep11 - Kiotóba megyünk Nyá",
    "ep12 - Az utolsó részben is cigizni fogok Nyá"
)

# Create output directory if necessary
$OutputDir = ".\video\dest"

if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Determine which episodes to process
if ($PSBoundParameters.ContainsKey("EpisodeNumber")) {
    $Episodes = @($EpisodeNumber)
}
else {
    $Episodes = 1..12
}

foreach ($Episode in $Episodes) {

    $Index = $Episode - 1

    $EnglishTitle = $EnglishTitles[$Index]
    $HungarianTitle = $HungarianTitles[$Index]

    $SourceVideo = ".\video\src\$EnglishTitle.mkv"
    $SubtitleFile = ".\sub\$HungarianTitle.ass"
    $OutputVideo = "$OutputDir\$HungarianTitle.mkv"

    Write-Host "Processing episode $Episode : $HungarianTitle"

    $Arguments = @(
        "-o", $OutputVideo,
        $SourceVideo,
        "--language", "0:hun",
        "--track-name", "0:Magyar fan sub",
        $SubtitleFile
    )

    & mkvmerge @Arguments

    if ($LASTEXITCODE -ne 0) {
        Write-Error "mkvmerge failed for episode $Episode (exit code: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
}
