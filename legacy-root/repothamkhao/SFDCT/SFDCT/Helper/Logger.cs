namespace SFDCT.Helper;

/// <summary>
/// Use this class to print messages to the console.
/// </summary>
internal static class Logger
{
    private static string _sLastPrintedLine = string.Empty;
    private static uint _sIdenticalLines = 1;

    private static void Print<T>(T message, bool newLine)
    {
        string text = message.ToString();
        if (text == _sLastPrintedLine)
        {
            _sIdenticalLines++;
            Console.SetCursorPosition(0, Console.CursorTop - 1);
        }
        else
        {
            _sLastPrintedLine = text;
            if (_sIdenticalLines > 1)
            {
                _sIdenticalLines = 1;
            }
        }

        if (newLine || _sIdenticalLines > 1)
        {
            Console.WriteLine(@"[{0:HH:mm:ss}] {1} {2}", DateTime.Now, _sLastPrintedLine, _sIdenticalLines > 1 ? _sIdenticalLines + "x" : string.Empty);
        }
        else if (_sIdenticalLines == 1)
        {
            Console.Write(@"[{0:HH:mm:ss}] {1} {2}", DateTime.Now, _sLastPrintedLine, _sIdenticalLines > 1 ? _sIdenticalLines + "x" : string.Empty);
        }
    }

    internal static void LogError<T>(T message, bool newLine = true)
    {
        CheckAndPrint(message, ConsoleColor.Red, 4, newLine);
    }

    internal static void LogWarn<T>(T message, bool newLine = true)
    {
        CheckAndPrint(message, ConsoleColor.Yellow, 3, newLine);
    }

    internal static void LogInfo<T>(T message, bool newLine = true)
    {
        CheckAndPrint(message, ConsoleColor.Cyan, 2, newLine);
    }

    internal static void LogDebug<T>(T message, bool newLine = true)
    {
        if (!Program.Debug) return;

        CheckAndPrint(message, ConsoleColor.DarkGray, 1, newLine);
    }

    internal static void Log<T>(T message, ConsoleColor color, bool newLine = true)
    {
        CheckAndPrint(message, color, 2, newLine);
    }

    private static void CheckAndPrint<T>(T message, ConsoleColor color, int requiredLevel, bool newLine)
    {
        Console.ForegroundColor = color;
        if (message != null)
        {
            Print(message, newLine);
        }
        else
        {
            Print("Trying to print null object!", newLine);
        }

        Console.ForegroundColor = ConsoleColor.Gray;
    }

    internal static string Truncate(this string value, int maxChars, string truncateChars = "..") => value.Length <= maxChars ? value : value.Substring(0, maxChars) + truncateChars;
}
