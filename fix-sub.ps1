
$SubtitleDir = ".\sub"

# Standard ASS header
$Header = @'
[Script Info]
Title: Chainsmoker Cat - Hungarian fan sub
ScriptType: v4.00+
WrapStyle: 0
ScaledBorderAndShadow: yes
YCbCr Matrix: TV.601
PlayResX: 640
PlayResY: 360

[V4+ Styles]
Format: Name,Fontname,Fontsize,PrimaryColour,SecondaryColour,OutlineColour,BackColour,Bold,Italic,Underline,StrikeOut,ScaleX,ScaleY,Spacing,Angle,BorderStyle,Outline,Shadow,Alignment,MarginL,MarginR,MarginV,Encoding

; Normal dialogue
Style: Default,Arial,24,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,1,0.3,2,15,15,18,1

; Internal thoughts
Style: Thought,Arial,24,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,1,0,0,100,100,0,0,1,1,0.3,2,15,15,18,1

; Signs and on-screen text
Style: Sign,Arial,24,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,1,0.3,8,15,15,12,1

'@

# Required closing dialogues
$EndingDialogues = @(
    'Dialogue: 0,0:23:32.91,0:23:37.91,Default,,0,0,0,,{\an8}Magyarította: DonBattery',
    'Dialogue: 0,0:23:37.99,0:23:38.83,Default,,0,0,0,,EZ A MŰ A KÉPZELET SZÜLEMÉNYE.',
    'Dialogue: 0,0:23:38.91,0:23:40.91,Default,,0,0,0,,KISKORÚAKNAK DOHÁNYOZNI ÉS ALKOHOLT FOGYASZTANI\NTILOS. NE UTÁNOZD!'
)

# Convert SRT timestamp to ASS timestamp
function Convert-SrtTimeToAss {
    param([string]$Time)

    # SRT: 00:00:01,234
    # ASS: 0:00:01.23
    if ($Time -match '^(\d{2}):(\d{2}):(\d{2}),(\d{3})$') {
        $Hours = [int]$Matches[1]
        $Minutes = [int]$Matches[2]
        $Seconds = [int]$Matches[3]
        $Centiseconds = [int]([math]::Floor([int]$Matches[4] / 10))

        return ('{0}:{1:00}:{2:00}.{3:00}' -f $Hours, $Minutes, $Seconds, $Centiseconds)
    }

    throw "Invalid SRT timestamp: $Time"
}

# Convert an SRT file into ASS dialogue lines
function Convert-SrtToAssDialogue {
    param([string]$FilePath)

    $Content = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8

    $Blocks = $Content -split '(?:\r?\n){2,}'

    $DialogueLines = @()

    foreach ($Block in $Blocks) {
        $Lines = $Block -split '\r?\n'

        if ($Lines.Count -lt 2) {
            continue
        }

        $TimestampLine = $Lines[1].Trim()

        if ($TimestampLine -notmatch '^(\d{2}:\d{2}:\d{2},\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2},\d{3})') {
            continue
        }

        $Start = Convert-SrtTimeToAssTime $Matches[1]
        $End = Convert-SrtTimeToAssTime $Matches[2]

        $TextLines = $Lines | Select-Object -Skip 2
        $Text = ($TextLines -join '\N')

        # Basic SRT markup conversion
        $Text = $Text -replace '<i>', '{\i1}'
        $Text = $Text -replace '</i>', '{\i0}'
        $Text = $Text -replace '<b>', '{\b1}'
        $Text = $Text -replace '</b>', '{\b0}'
        $Text = $Text -replace '<u>', '{\u1}'
        $Text = $Text -replace '</u>', '{\u0}'
        $Text = $Text -replace '<font[^>]*>', ''
        $Text = $Text -replace '</font>', ''
        $Text = $Text -replace '<[^>]+>', ''

        $DialogueLines += "Dialogue: 0,$Start,$End,Default,,0,0,0,,$Text"
    }

    return $DialogueLines
}

# Alias function for timestamp conversion
function Convert-SrtTimeToAssTime {
    param([string]$Time)

    return Convert-SrtTimeToAss $Time
}

# Process SRT files first, converting them into ASS
$SrtFiles = Get-ChildItem -LiteralPath $SubtitleDir -Filter "*.srt" -File

foreach ($File in $SrtFiles) {
    $AssPath = Join-Path $SubtitleDir ($File.BaseName + ".ass")

    Write-Host "Converting $($File.Name) to ASS..."

    $DialogueLines = Convert-SrtToAssDialogue $File.FullName

    $Content = $Header + "`r`n[Events]`r`nFormat: Layer,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text`r`n"
    $Content += ($DialogueLines -join "`r`n") + "`r`n"

    Set-Content -LiteralPath $AssPath -Value $Content -Encoding UTF8
}

# Process every ASS file, including those just converted
$AssFiles = Get-ChildItem -LiteralPath $SubtitleDir -Filter "*.ass" -File

foreach ($File in $AssFiles) {
    Write-Host "Normalizing $($File.Name)..."

    $Content = Get-Content -LiteralPath $File.FullName -Raw -Encoding UTF8

    # Extract the existing Events section
    $EventLines = @()

    if ($Content -match '(?ms)^\[Events\]\s*\r?\n(.*?)(?=^\[|\z)') {
        $ExistingEvents = $Matches[1]

        $EventLines = @(
            $ExistingEvents -split '\r?\n' |
            Where-Object {
                $_ -match '^(Dialogue|Comment):'
            }
        )
    }

    # Add the required closing dialogues if they are missing
    foreach ($Dialogue in $EndingDialogues) {
        if ($EventLines -notcontains $Dialogue) {
            $EventLines += $Dialogue
        }
    }

    # Rebuild the file using the standard header
    $FinalContent = $Header + "`r`n[Events]`r`nFormat: Layer,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text`r`n"
    $FinalContent += ($EventLines -join "`r`n") + "`r`n"

    Set-Content -LiteralPath $File.FullName -Value $FinalContent -Encoding UTF8
}

Write-Host "Subtitle processing completed."
