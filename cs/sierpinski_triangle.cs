#if !CODE_ANALYSIS
  #define CODE_ANALYSIS
#endif

using System;
using System.Linq;
using System.Drawing;
using System.Reflection;
using System.Windows.Forms;
using System.ComponentModel;
using System.Drawing.Drawing2D;
using System.Diagnostics.CodeAnalysis;

[assembly: AssemblyCompany("")]
[assembly: AssemblyCopyright("")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyTitle("Sierpinski Triangle")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: CLSCompliant(true)]

namespace SierpinskiTriangle {
  internal sealed class AssemblyInfo {
    private  Type a;
    internal AssemblyInfo() { a = typeof(Program); }

    internal String Title {
      get {
        return ((AssemblyTitleAttribute)Attribute.GetCustomAttribute(
            a.Assembly, typeof(AssemblyTitleAttribute)
        )).Title;
      }
    }
  } // AssemblyInfo

  internal sealed class frmMain : Form {
    public frmMain() {
      InitializeComponent();
      this.Text = new AssemblyInfo().Title;
    }

    private IContainer components = null;

    protected override void Dispose(Boolean disposing) {
      if (disposing && (null != components))
        components.Dispose();
      base.Dispose(disposing);
    }

    private Label         lblLevel;
    private NumericUpDown nudLevel;
    private Button        btnDraw;
    private PictureBox    pbImage;

    [SuppressMessage("Microsoft.Globalization", "CA1303:DoNotPassLiteralsAsLocalizedParameters")]
    private void InitializeComponent() {
      this.lblLevel = new Label();
      this.nudLevel = new NumericUpDown();
      this.btnDraw  = new Button();
      this.pbImage  = new PictureBox();
      //
      // lblLevel
      //
      this.lblLevel.Location = new Point(12, 17);
      this.lblLevel.Size = new Size(36, 13);
      this.lblLevel.Text = "Level:";
      //
      // nudLevel
      //
      this.nudLevel.Location = new Point(49, 14);
      this.nudLevel.Size = new Size(39, 20);
      this.nudLevel.Maximum = 9;
      this.nudLevel.Minimum = 0;
      this.nudLevel.TextAlign = HorizontalAlignment.Right;
      this.nudLevel.Value = 3;
      //
      // btnDraw
      //
      this.btnDraw.Location = new Point(91, 12);
      this.btnDraw.Size = new Size(75, 23);
      this.btnDraw.Text = "Draw";
      this.btnDraw.Click += (s, e) => { DrawFractal(); };
      //
      // pbImage
      //
      this.pbImage.Anchor = ((AnchorStyles.Top | AnchorStyles.Bottom) | AnchorStyles.Left) | AnchorStyles.Right;
      this.pbImage.BackColor = Color.White;
      this.pbImage.BorderStyle = BorderStyle.Fixed3D;
      this.pbImage.Location = new Point(12, 41);
      this.pbImage.Size = new Size(285, 208);
      //
      // frmMain
      //
      this.ClientSize = new Size(309, 261);
      this.Controls.AddRange(new Control[] {this.lblLevel, this.nudLevel, this.btnDraw, this.pbImage});
      this.FormBorderStyle = FormBorderStyle.FixedSingle;
      this.StartPosition = FormStartPosition.CenterScreen;
      this.Load += (s, e) => { DrawFractal(); };
      this.Resize += (s, e) => { DrawFractal(); };
    } // InitializeComponent

    [SuppressMessage("Microsoft.Reliability", "CA2000:DisposeObjectsBeforeLosingScope")]
    private void DrawFractal() {
      Bitmap bmp = new Bitmap(pbImage.ClientSize.Width, pbImage.ClientSize.Height);
      using (Graphics g = Graphics.FromImage(bmp)) {
        g.Clear(Color.White);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        // top-level triangle points (top, left, right)
        PointF[] points = new [] {
          new PointF (pbImage.ClientSize.Width / 2f, 10),
          new PointF (10, pbImage.ClientSize.Height - 10),
          new PointF (pbImage.ClientRectangle.Right - 10, pbImage.ClientRectangle.Bottom - 10)
        };
        DrawTriangle(g, (Int32)nudLevel.Value, points[0], points[1], points[2]);
      }
      // backup old image
      Image img = pbImage.Image;
      // show current image
      pbImage.Image = bmp;
      // release old image
      if (null != img) img.Dispose();
    } // DrawFractal

    private void DrawTriangle(Graphics g, Int32 level, PointF top, PointF left, PointF right) {
      if (0 == level) { // draw triangle
        g.FillPolygon(Brushes.DarkMagenta, new PointF[] {top, left, right});
      }
      else {
        PointF[] points = new [] {
          new PointF ((top.X + left.X) / 2f, (top.Y + left.Y) / 2f),
          new PointF ((top.X + right.X) / 2f, (top.Y + right.Y) / 2f),
          new PointF ((left.X + right.X) / 2f, (left.Y + right.Y) / 2f)
        };
        // draw small triangles
        DrawTriangle(g, level - 1, top, points[0], points[1]);
        DrawTriangle(g, level - 1, points[0], left, points[2]);
        DrawTriangle(g, level - 1, points[1], points[2], right);
      }
    }
  } // frmMain

  internal sealed class Program {
    [STAThread]
    static void Main() {
      Application.EnableVisualStyles();
      Application.Run(new frmMain());
    }
  } // Program
}
