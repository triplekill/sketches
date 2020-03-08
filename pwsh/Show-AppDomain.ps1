#requires -version 7
using namespace System.Drawing
using namespace System.Reflection
using namespace System.Windows.Forms

Add-Type -AssemblyName System.Windows.Forms

function New-FormElements {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Array]$Names,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNullOrEmpty()]
    [Type[]]$Elements,

    [Parameter(Mandatory, Position=2)]
    [ValidateNotNullOrEmpty()]
    [Hashtable]$Property
  )

  end {
    if ($names.Length -ne $Elements.Length) {
      throw [InvalidOperationException]::new('Element mismatch.')
    }

    for ($i = 0; $i -lt $Names.Length; $i++) {
      if (($x = $Names[$i]) -is [Array]) {
        (1..$x.Length).ForEach{
          Set-Variable -Name "$($x[0])$_" -Value (
            New-Object $Elements[$i] -Property $Property[$Elements[$i].Name]
          ) -Scope Script -Force
        }
      }
      else {
        Set-Variable -Name $x -Value (
          New-Object $Elements[$i] -Property $Property[$Elements[$i].Name]
        ) -Scope Script -Force
      }
    }
  }
}

New-FormElements -Names (
  'frmMain', 'mnuMain', (,'mnuSub' * 4), (,'scSplt' * 2), 'tvRoots',
  (,'lvList' * 2), (,'chCol_' * 5), 'sbStrip', 'sbLabel'
) -Elements (
  [Form], [MenuStrip], [ToolStripMenuItem], [SplitContainer], [TreeView],
  [ListView], [ColumnHeader], [StatusStrip], [ToolStripMenuItem]
) -Property @{
  Form = @{
    ClientSize = [Size]::new(800, 600)
    MainMenuStrip = $mnuMain
    StartPosition = [FormStartPosition]::CenterScreen
    Text = 'AppDomain Explorer'
  }
  ListView = @{
    Dock = [DockStyle]::Fill
    FullRowSelect = $true
    Multiselect = $false
    ShowItemToolTips = $false
    Sorting = [SortOrder]::Ascending
    View = [View]::Details
  }
  SplitContainer = @{
    Dock = [DockStyle]::Fill
    SplitterWidth = 1
  }
  TreeView = @{
    Dock = [DockStyle]::Fill
    Sorted = $true
  }
}
#
# main menu
#
$mnuMain.Items.AddRange(($mnuSub1, $mnuSub2))
$mnuSub1.DropDownItems.AddRange(($mnuSub3))
$mnuSub1.Text = '&File'
$mnuSub3.ShortcutKeys = [Keys]::Control, [Keys]::X
$mnuSub3.Text = 'E&xit'
$mnuSub3.Add_Click({$frmMain.Close()})
$mnuSub2.DropDownItems.AddRange(($mnuSub4))
$mnuSub2.Text = '&View'
$mnuSub4.Checked = $true
$mnuSub4.Text = '&Status Bar'
$mnuSub4.Add_Click({
  $toggle =! $mnuSub4.Checked
  $mnuSub4.Checked = $toggle
  $sbStrip.Visible = $toggle
})
#
# split containers
#
$scSplt1.Panel1.Controls.Add($tvRoots)
$scSplt1.Panel2.Controls.Add($scSplt2)
$scSplt2.Orientation = [Orientation]::Horizontal
$scSplt2.Panel1.Controls.Add($lvList1)
$scSplt2.Panel2.Controls.Add($lvList2)
$scSplt2.SplitterDistance = 50
#
# tree view
#
$tvRoots.Add_BeforeExpand({
  $_.Node.Nodes.Clear()

  foreach ($type in $_.Node.Tag.GetTypes()) {
    $node = $_.Node.Nodes.Add($type.FullName)
    $node.Tag = $type
  }
})
$tvRoots.Add_BeforeSelect({
  ($lvList1, $lvList2).ForEach{$_.Items.Clear()}

  foreach ($prop in $_.Node.Tag.PSObject.Properties) {
    $item = $lvList1.Items.Add($prop.Name)

    switch (($prop.Value -ne $null)) {
      $true {
        $item.SubItems.Add($prop.Value.ToString())
        $item.ForeColor = $prop.Value ? [Color]::DarkBlue : [Color]::Crimson
      }
      default {
        $item.ForeColor = [Color]::Gray
        $item.SubItems.Add('<NULL>')
      }
    }
  }

  try {
    ($_.Node.Tag -as [Type]).GetMembers(
      [BindingFlags]'Instance, Static, Public, NonPublic, InvokeMethod'
    ).ForEach{
      $item = $lvList2.Items.Add($_.Name)
      $item.SubItems.Add(($x = $_.MemberType.ToString()))
      $item.SubItems.Add($_.ToString())
      $item.ForeColor = $(switch ($x) {
        'constructor' { [Color]::DarkGray }
        'field'       { [Color]::DarkGreen }
        'method'      { [Color]::DarkMagenta }
        'property'    { [Color]::DarkCyan }
      })
    }
  }
  catch {}

  ($lvList1, $lvList2).ForEach{
    $_.AutoResizeColumns([ColumnHeaderAutoResizeStyle]::ColumnContent)
  }
  $sbLabel.Text = $_.Node.Tag
})
#
# list views
#
$lvList1.Columns.AddRange(($chCol_1, $chCol_2))
$lvList2.Columns.AddRange(($chCol_3, $chCol_4, $chCol_5))
$chCol_1.Text = $chCol_3.Text = 'Name'
$chCol_2.Text = 'Property'
$chCol_4.Text = 'Member'
$chCol_5.Text = 'Definition'
#
# status strip
#
$sbStrip.Items.AddRange(($sbLabel))
$sbLabel.AutoSize = $true
#
# main form
#
$frmMain.Controls.AddRange(($scSplt1, $sbStrip, $mnuMain))
$frmMain.Add_Load({
  [AppDomain]::CurrentDomain.GetAssemblies().ForEach{
    if (($$ = $_.GetName().Name) -notmatch 'resources$') {
      $node = New-Object TreeNode -Property @{
        Text = $$
        Tag = $_
      }

      $tvRoots.Nodes.Add($node)
      $node.Nodes.Add('<NULL>')
    }
  }
})
[void]$frmMain.ShowDialog()
