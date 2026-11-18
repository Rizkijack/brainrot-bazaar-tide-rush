// Small focus-and-capture helper. Compiled with csc.exe and called by capture.ps1.
// Other windows on this machine repeatedly steal focus, so the capture uses
// PrintWindow (PW_RENDERFULLCONTENT) to read the Studio window directly, then
// scales it to exactly 1280x720 and saves it as a quality-controlled JPEG.
using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public class FocusCapture
{
    [StructLayout(LayoutKind.Sequential)]
    struct RECT { public int Left, Top, Right, Bottom; }

    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int w, int h, uint flags);

    static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);
    const uint SWP_NOMOVE = 0x0002, SWP_NOSIZE = 0x0001, SWP_SHOWWINDOW = 0x0040;

    static int Main(string[] args)
    {
        if (args.Length < 2) { Console.Error.WriteLine("usage: focus-capture.exe <pid> <output.jpg>"); return 1; }
        int pid = int.Parse(args[0]);
        string output = args[1];
        Process studio = Process.GetProcessById(pid);
        IntPtr hwnd = studio.MainWindowHandle;
        if (hwnd == IntPtr.Zero) { Console.Error.WriteLine("studio has no window"); return 1; }

        ShowWindow(hwnd, 3); // SW_MAXIMIZE
        SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
        SetForegroundWindow(hwnd);
        System.Threading.Thread.Sleep(250);

        try
        {
            RECT rect;
            if (!GetWindowRect(hwnd, out rect)) { Console.Error.WriteLine("GetWindowRect failed"); return 1; }
            int w = Math.Max(1, rect.Right - rect.Left);
            int h = Math.Max(1, rect.Bottom - rect.Top);
            using (Bitmap window = new Bitmap(w, h))
            {
                using (Graphics g = Graphics.FromImage(window))
                {
                    IntPtr hdc = g.GetHdc();
                    bool ok = PrintWindow(hwnd, hdc, 2); // PW_RENDERFULLCONTENT
                    g.ReleaseHdc(hdc);
                    if (!ok) { Console.Error.WriteLine("PrintWindow failed"); return 1; }
                }
                using (Bitmap target = new Bitmap(1280, 720))
                {
                    using (Graphics canvas = Graphics.FromImage(target))
                    {
                        canvas.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        canvas.DrawImage(window, 0, 0, 1280, 720);
                    }
                    SaveJpeg(target, output, 80);
                    if (new FileInfo(output).Length > 260000) SaveJpeg(target, output, 65);
                    Console.WriteLine(new FileInfo(output).Length);
                }
            }
        }
        finally
        {
            SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
        }
        return 0;
    }

    static void SaveJpeg(Bitmap bitmap, string path, int quality)
    {
        ImageCodecInfo codec = null;
        foreach (ImageCodecInfo c in ImageCodecInfo.GetImageEncoders())
            if (c.MimeType == "image/jpeg") { codec = c; break; }
        using (EncoderParameters options = new EncoderParameters(1))
        {
            options.Param[0] = new EncoderParameter(Encoder.Quality, (long)quality);
            bitmap.Save(path, codec, options);
        }
    }
}
