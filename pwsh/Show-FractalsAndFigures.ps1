#requires -version 7
using namespace System.Drawing
using namespace System.Numerics
using namespace System.Windows.Forms

Add-Type -AssemblyName System.Windows.Forms

$mnuDo_1 = New-Object ToolStripMenuItem -Property @{
  Text = 'Mandelbrot Set'
}
$mnuDo_1.Add_Click({
  $this = $frmMain # switch context
  $frmTemp = New-Object Form -Property @{
    BackgroundImage = ($bmp = [Bitmap]::new(320, 320))
    FormBorderStyle = [FormBorderStyle]::FixedSingle
    MaximizeBox = $false
    MdiParent = $this
    Size = [Size]::new(316, 339)
    StartPosition = [FormStartPosition]::CenterParent
    Text = 'Mandelbrot Set'
  }
  $frmTemp.Add_Load({
    foreach ($r in 0..299) {
      foreach ($m in 0..299) {
        $i = 99
        $k = $c = [Complex]::new(($m / 75 - 2), ($r / 75 - 2))
        while (($k *= $k).Magnitude -lt 4 -and $i--) { $k += $c }
        $bmp.SetPixel($m, $r, [Color]::FromArgb(-5e6*++$i))
      }
    }
  })
  $frmTemp.Add_FormClosing({ if ($bmp) {$bmp.Dispose()} })
  [void]$frmTemp.Show()
  $sbLabel.Text = 'Mandelbrot Set'
})

$mnuNull = [ToolStripSeparator]::new()
$mnuExit = New-Object ToolStripMenuItem -Property @{
  ShortcutKeys = [Keys]::Control, [Keys]::X
  Text = 'E&xit'
}
$mnuExit.Add_Click({$frmMain.Close()})

$mnuPack = New-Object ToolStripMenuItem -Property @{
  Text = '&Fractals'
}
$mnuPack.DropDownItems.AddRange(($mnuDo_1, $mnuNull, $mnuExit))

$mnuSBar = New-Object ToolStripMenuItem -Property @{
  Checked = $true
  Text = '&Status Bar'
}
$mnuSBar.Add_Click({
  $toggle =! $mnuSBar.Checked
  $mnuSBar.Checked = $toggle
  $sbStrip.Visible = $toggle
})

$mnuView = New-Object ToolStripMenuItem -Property @{
  Text = '&View'
}
$mnuView.DropDownItems.AddRange(($mnuSBar))

$mnuMain = [MenuStrip]::new()
$mnuMain.Items.AddRange(($mnuPack, $mnuView))

$sbLabel = New-Object ToolStripMenuItem -Property @{
  AutoSize = $true
}

$sbStrip = [StatusStrip]::new()
$sbStrip.Items.AddRange(($sbLabel))

$frmMain = New-Object Form -Property @{
  ClientSize = [Size]::new(520, 390)
  IsMdiContainer = $true
  MainMenuStrip = $mnuMain
  StartPosition = [FormStartPosition]::CenterScreen
  Text = 'FractalsAndFigures'
}
$frmMain.Controls.AddRange(($sbStrip, $mnuMain))
$frmMain.Add_Load({$sbLabel.Text = 'Ready'})
[void]$frmMain.ShowDialog()
