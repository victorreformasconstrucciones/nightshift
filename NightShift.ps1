Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object Windows.Forms.Form
$form.Text = 'NightShift'
$form.ClientSize = New-Object Drawing.Size(900, 570)
$form.MinimumSize = $form.Size
$form.BackColor = [Drawing.Color]::FromArgb(18, 19, 24)
$form.ForeColor = [Drawing.Color]::WhiteSmoke
$form.Font = New-Object Drawing.Font('Segoe UI', 11)
$form.StartPosition = 'CenterScreen'

$menu = New-Object Windows.Forms.ListBox
$menu.SetBounds(20, 25, 210, 515)
$menu.BackColor = [Drawing.Color]::FromArgb(34, 35, 43)
$menu.ForeColor = [Drawing.Color]::WhiteSmoke
$menu.Items.AddRange([object[]]@('Рыбалка','Лесоруб','Карьер','Стройка','Охотник','Фермер','Грибник','Качалка','Швейка','Таксист','Угонщик'))
$form.Controls.Add($menu)

function Add-Label($text, $x, $y, $width, $height, $size) {
    $label = New-Object Windows.Forms.Label
    $label.Text = $text
    $label.SetBounds($x, $y, $width, $height)
    $label.Font = New-Object Drawing.Font('Segoe UI', $size)
    $form.Controls.Add($label)
    return $label
}

$title = Add-Label 'Рыбалка' 260 28 600 65 30
$status = Add-Label '' 263 125 600 90 18
$stats = Add-Label '' 263 238 600 50 14

function Add-Button($text, $x, $color) {
    $button = New-Object Windows.Forms.Button
    $button.Text = $text
    $button.SetBounds($x, 325, 175, 52)
    $button.FlatStyle = 'Flat'
    $button.BackColor = $color
    $form.Controls.Add($button)
    return $button
}

$red = [Drawing.Color]::FromArgb(159, 20, 55)
$gray = [Drawing.Color]::FromArgb(42, 43, 52)
$start = Add-Button 'Запустить' 263 $red
$stop = Add-Button 'Остановить' 454 $gray
$hook = Add-Button 'Подсечь' 645 $red
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 100
$clock = New-Object Diagnostics.Stopwatch
$session = @{ Catch = 0; Due = 0; Biting = $false }
$random = New-Object Random

function Reset-Cast {
    $session.Biting = $false
    $session.Due = $clock.ElapsedMilliseconds + $random.Next(1800, 5500)
    $hook.Enabled = $false
    $status.Text = 'Ожидание поклёвки…'
}
function Stop-Fishing {
    $timer.Stop()
    $clock.Stop()
    $start.Enabled = $true
    $stop.Enabled = $false
    $hook.Enabled = $false
}
$timer.Add_Tick({
    $elapsed = $clock.ElapsedMilliseconds
    $stats.Text = 'Улов: {0}     Время: {1:mm\:ss}' -f $session.Catch, $clock.Elapsed
    if ($elapsed -ge $session.Due) {
        if ($session.Biting) {
            Reset-Cast
            $status.Text = 'Рыба сорвалась. Новый заброс…'
        } else {
            $session.Biting = $true
            $session.Due = $elapsed + 1200
            $hook.Enabled = $true
            $status.Text = 'Клюёт! Подсекай.'
        }
    }
})
$start.Add_Click({
    $session.Catch = 0
    $clock.Restart()
    Reset-Cast
    $start.Enabled = $false
    $stop.Enabled = $true
    $timer.Start()
})
$stop.Add_Click({ Stop-Fishing; $status.Text = 'Тренировка остановлена' })
$hook.Add_Click({
    if ($timer.Enabled -and $session.Biting -and $clock.ElapsedMilliseconds -lt $session.Due) {
        $session.Catch++
        Reset-Cast
        $status.Text = 'Поймал! Новый заброс…'
    }
})
$menu.Add_SelectedIndexChanged({
    Stop-Fishing
    $title.Text = [string]$menu.SelectedItem
    $fishing = $menu.SelectedIndex -eq 0
    $start.Visible = $stop.Visible = $hook.Visible = $stats.Visible = $fishing
    $stats.Text = 'Улов: 0     Время: 00:00'
    if ($fishing) { $status.Text = 'Офлайн-тренажёр. Нажми «Запустить».' }
    else { $status.Text = 'Раздел пока в разработке.' }
})
$menu.SelectedIndex = 0
try { [void]$form.ShowDialog() }
finally { $timer.Dispose(); $form.Dispose() }
