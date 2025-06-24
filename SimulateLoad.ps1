# SimulateLoad.ps1
# A script to simulate load on the Weather API service for testing OpenTelemetry

param (
    [string]$BaseUrl = "http://localhost:8080",
    [int]$DurationMinutes = 5,
    [int]$ConcurrentUsers = 5,
    [int]$DelayMilliseconds = 200
)

# Define the API endpoints to test
$endpoints = @(
    @{
        Method = "GET"
        Path = "/weather"
        Description = "Get all forecasts"
    },
    @{
        Method = "POST" 
        Path = "/weather" 
        Description = "Create new forecast"
        Body = @{
            date = (Get-Date).ToString("o")
            temperatureC = Get-Random -Minimum -20 -Maximum 55
            summary = "Generated Forecast"
        }
    },
    @{
        Method = "GET" 
        Path = "/weather/1" 
        Description = "Get forecast by ID"
    }
)

# Function to make a single API request
function Invoke-ApiRequest {
    param (
        [string]$Method,
        [string]$Url,
        [PSCustomObject]$Body = $null
    )
    
    $headers = @{
        "Content-Type" = "application/json"
        "User-Agent" = "PowerShell-LoadTest"
    }
    
    $params = @{
        Method = $Method
        Uri = $Url
        Headers = $headers
        UseBasicParsing = $true
        ErrorAction = "SilentlyContinue"
    }
    
    if ($Body -and $Method -eq "POST") {
        $params["Body"] = ($Body | ConvertTo-Json)
    }
    
    try {
        $response = Invoke-RestMethod @params
        return @{
            StatusCode = 200
            Success = $true
            ResponseTime = $responseTime
            Response = $response
        }
    }
    catch {
        return @{
            StatusCode = $_.Exception.Response.StatusCode.value__
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Function to simulate a user session
function Start-UserSession {
    param (
        [int]$UserId,
        [DateTime]$EndTime
    )
    
    Write-Host "Starting user session $UserId"
    
    # Current endpoint index for ordered execution
    $endpointIndex = 0
    
    while ((Get-Date) -lt $EndTime) {
        # Use endpoints in ordered sequence instead of random selection
        $endpoint = $endpoints[$endpointIndex]
        
        # Create a unique body for POST requests with random temperature
        if ($endpoint.Method -eq "POST") {
            $endpoint.Body.temperatureC = Get-Random -Minimum -20 -Maximum 55
            $endpoint.Body.date = (Get-Date).ToString("o")
        }
        
        $url = "$BaseUrl$($endpoint.Path)"
        
        Write-Host "User $UserId - $($endpoint.Method) $url - $($endpoint.Description)"
        
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Invoke-ApiRequest -Method $endpoint.Method -Url $url -Body $endpoint.Body
        $sw.Stop()
        
        Write-Host "User $UserId - Response: Status=$($result.StatusCode), Time=$($sw.ElapsedMilliseconds)ms"
        
        # Move to next endpoint in sequence, wrapping around to the beginning
        $endpointIndex = ($endpointIndex + 1) % $endpoints.Count
        
        # Random delay between requests
        Start-Sleep -Milliseconds (Get-Random -Minimum ($DelayMilliseconds/2) -Maximum ($DelayMilliseconds*1.5))
    }
    
    Write-Host "User session $UserId completed"
}

# Main execution
Write-Host "Starting load simulation against $BaseUrl for $DurationMinutes minutes with $ConcurrentUsers concurrent users"
Write-Host "Each user will cycle through: GET all, POST new, GET by ID"
$endTime = (Get-Date).AddMinutes($DurationMinutes)

# Start user sessions in parallel
$jobs = @()
for ($i = 1; $i -le $ConcurrentUsers; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($userId, $baseUrl, $endTime, $delayMs, $endpointsData)
        
        # Redefine function in job scope
        function Invoke-ApiRequest {
            param (
                [string]$Method,
                [string]$Url,
                [PSCustomObject]$Body = $null
            )
            
            $headers = @{
                "Content-Type" = "application/json"
                "User-Agent" = "PowerShell-LoadTest"
            }
            
            $params = @{
                Method = $Method
                Uri = $Url
                Headers = $headers
                UseBasicParsing = $true
                ErrorAction = "SilentlyContinue"
            }
            
            if ($Body -and $Method -eq "POST") {
                $params["Body"] = ($Body | ConvertTo-Json)
            }
            
            try {
                $response = Invoke-RestMethod @params
                return @{
                    StatusCode = 200
                    Success = $true
                    Response = $response
                }
            }
            catch {
                return @{
                    StatusCode = $_.Exception.Response.StatusCode.value__
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        }
        
        Write-Host "Starting user session $userId"
        
        # Current endpoint index for ordered execution
        $endpointIndex = 0
        
        while ((Get-Date) -lt $endTime) {
            # Use endpoints in ordered sequence instead of random selection
            $endpoint = $endpointsData[$endpointIndex]
            
            # Create a unique body for POST requests with random temperature
            if ($endpoint.Method -eq "POST") {
                $endpoint.Body.temperatureC = Get-Random -Minimum -20 -Maximum 55
                $endpoint.Body.date = (Get-Date).ToString("o")
            }
            
            $url = "$baseUrl$($endpoint.Path)"
            
            Write-Host "User $userId - $($endpoint.Method) $url - $($endpoint.Description)"
            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-ApiRequest -Method $endpoint.Method -Url $url -Body $endpoint.Body
            $sw.Stop()
            
            Write-Host "User $userId - Response: Status=$($result.StatusCode), Time=$($sw.ElapsedMilliseconds)ms"
            
            # Move to next endpoint in sequence, wrapping around to the beginning
            $endpointIndex = ($endpointIndex + 1) % $endpointsData.Count
            
            # Random delay between requests
            Start-Sleep -Milliseconds (Get-Random -Minimum ($delayMs/2) -Maximum ($delayMs*1.5))
        }
        
        Write-Host "User session $userId completed"
    } -ArgumentList $i, $BaseUrl, $endTime, $DelayMilliseconds, $endpoints
}

# Wait for all jobs to complete
Write-Host "All user sessions started. Waiting for completion..."
$jobs | Wait-Job | Receive-Job

Write-Host "Load simulation completed at $(Get-Date)"