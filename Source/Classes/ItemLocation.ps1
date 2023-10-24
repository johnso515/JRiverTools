class ItemLocation {
    <# Define the class. Try constructors, properties, or methods. #>
    [string]$Drive
    [System.IO.DirectoryInfo]$Path
    [string]$PathString
    [string]$ComputerName    # The name of the computer where the path/drive exists

    [string] GetPathString () {
        <# Action to perform. You can use $ to reference the current instance of this class #>
        if ($null -eq $this.Path) {
            return $this.PathString
        }
        else {
            return $this.Path.FullName
        }
    }
}