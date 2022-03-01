function LibraryOpenCriticScores()
{
    param(
        $scriptMainMenuItemActionArgs
    )

    foreach($game in $PlayniteApi.Database.Games)
    {
        # $PlayniteApi.Dialogs.ShowMessage($game.Name + ': ' + $game.CriticScore)
        getOCScores($game)
    }
}

function OpenCriticScores()
{
    param(
        $scriptGameMenuItemActionArgs
    )

    # TODO figure out how to close the context menu when the script is running. 
    # (call a function instead of looping in this function??)
    # TODO possibly figure out how to show a dialog with remaining games.
    foreach($game in $scriptGameMenuItemActionArgs.Games)
    {
        # $PlayniteApi.Dialogs.ShowMessage($game.Name + ': ' + $game.CriticScore)
        getOCScores($game)
    }

}

function GetMainMenuItems()
{
    param(
        $getMainMenuItemsArgs
    )

    $menuItem = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem.Description = "Get Open Critic Scores"
    $menuItem.FunctionName = "LibraryOpenCriticScores"
    $menuItem.MenuSection = "@"
    return $menuItem
}

function GetGameMenuItems()
{
    param(
        $getGameMenuItemsArgs
    )

    $menuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $menuItem.Description = "Get Open Critic Scores"
    $menuItem.FunctionName = "OpenCriticScores"
    return $menuItem
}

function OCAPIGameSearch()
{
    param($GameName)

    $SearchBaseURL = 'https://api.opencritic.com/api/game/search?criteria='
    $SearchURL = $SearchBaseURL + $GameName

    try
    {
        $Response = Invoke-WebRequest -URI $SearchURL
        $StatusCode = $Response.StatusCode
        $__logger.Info("Open Critic API request succeeded for " + $GameName + " with status code " +  $StatusCode)
    }
    catch
    {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        $__logger.Error("Open Critic API request failed for " + $GameName + " with status code " +  $StatusCode)

    }

    return $Response
}

function OCAPIGameInfo()
{
    param($id)

    $GameBaseURL = 'https://api.opencritic.com/api/game/'
    $GameURL = $GameBaseURL + $id

    try
    {
        $Response = Invoke-WebRequest -URI $GameURL
        $StatusCode = $Response.StatusCode
        $__logger.Info("Open Critic API request succeeded for game ID " + $id + " with status code " +  $StatusCode)
    }
    catch
    {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        $__logger.Error("Open Critic API request failed for game ID " + $id + " with status code " +  $StatusCode)

    }

    return $Response
}

function getOCScores()
{
    param($Game)

    $OCTagBase = '[OC] '

    $GameName = $Game.Name
    $Response = OCAPIGameSearch($GameName)
    $GameList = $Response.Content | ConvertFrom-Json

    $FirstItem = $GameList[0]
    if($FirstItem.dist -eq 0)
    {
        $__logger.Info('Exact match: ' + $FirstItem.name + ': ' + $FirstItem.id)
        $ReseponseGame = OCAPIGameInfo($FirstItem.id)
        $OCGame = $ReseponseGame.Content | ConvertFrom-Json
        
        # $PlayniteApi.Dialogs.ShowMessage($OCGame.Name + ': ' + [int]$OCGame.topCriticScore + ' ('+$OCGame.tier+')')

        if($OCGame.topCriticScore)
        {
            if($OCGame.topCriticScore -eq -1)
            {
                $__logger.Info($OCGame.Name + ': Top Critic Score is unavailable')    
                return
            }
            $Game.CriticScore = $OCGame.topCriticScore
            $__logger.Info($OCGame.Name + ': ' + [int]$OCGame.topCriticScore + ' ('+$OCGame.tier+')')   
        }
        else 
        {
            $__logger.Info($OCGame.Name + ': Top Critic Score is unavailable')    
            return
        }
        
        if(-Not $PlayniteApi.Database.Tags)
        {
            $Tags = @()
        }
        else
        {
            $Tags = $PlayniteApi.Database.Tags
        }
        $TagFlag = $false
        $OCTagName = $OCTagBase + $OCGame.tier
        foreach($tag in $Tags)
        {
            if($tag.Name -eq $OCTagName)
            {
                $__logger.Info([string]$tag.Id + " : " + $tag.Name)
                $TagFlag = $true
                $OCTag = $tag
                
            }
        }
        if(-Not $TagFlag)
        {
            $__logger.Info("Adding new tag to Database: " + $OCTagName)
            $OCTag = New-Object "Playnite.SDK.Models.Tag"
            $OCTag.Name = $OCTagName
            $PlayniteApi.Database.Tags.Add($OCTag)
        }

        if(-Not $Game.TagIds)
        {
            $TagIds = @()
        }
        else
        {
            $TagIds = $Game.TagIds
        }

        If(-Not $TagIds.contains($OCTag.Id))
        {
            $__logger.Info("Adding tag to game: " + $OCTagName)
            $Game.TagIds += $OCTag.Id
        }


        # Consider adding link to game page in links metadata.
        # had to disable this because not all games have urls in the game json
        # $OCLink = New-Object "Playnite.SDK.Models.Link"
        # $OCLink.Name = "Open Critic"
        # $OCLink.Url = $OCGame.url
        # $Game.Links += $OCLink
        $PlayniteApi.Database.Games.Update($Game)
    }
    else 
    {
        # TODO Create a working game selection dialog
        $__logger.Info('Could not find exact match for: ' + $GameName)
        # $windowCreationOptions = New-Object Playnite.SDK.WindowCreationOptions
        # $windowCreationOptions.ShowMinimizeButton = $false

        # $window = $PlayniteApi.Dialogs.CreateWindow($windowCreationOptions)
        # $window.Height = 768
        # $window.Width = 768
        # $window.Title = 'Select OpenCritic Game'
        # $window.Content = 'Something'
        
        # TODO Populate grid with results and select best match.
        # $button = $window.Content.FindName("MyButton")
        # $button.Add_Click({
        #     $button.Conte
        # })
        

        # $grid = [System.Windows.Controls]::new([Grid])
        # $grid.Width = 250
        # $grid.Height = 100
        # $grid.HorizontalAlignment = HorizontalAlignment.Left
        # $grid.VerticalAlignment = VerticalAligment.Top
        # $grid.ShowGridLines = $false
        # $col1 = [System.Windows.Controls]::new([ColumnDefinition])
        # $col2 = [System.Windows.Controls]::new([ColumnDefinition])
        # $col3 = [System.Windows.Controls]::new([ColumnDefinition])
        # $grid.add($col1)
        # $grid.add($col2)
        # $grid.add($col3)

        # foreach($i in $GameList.Count)
        # {
        #     $row = [System.Windows.Controls]::new([RowDefinition])
        #     $grid.add($row)
        #     $grid.setRow($GameList[$i].name,$i)
        #     $grid.setColumn($GameList[$i].name,0)
        #     $grid.setRow($GameList[$i].id,$i)
        #     $grid.setColumn($GameList[$i].id,1)
        #     $grid.setRow($GameList[$i].dist,$i)
        #     $grid.setColumn($GameList[$i].dist,2)
        # }
        # $window.ShowDialog()

    }

}

# Dialog to select game to use for ratings
# See HowLongtoBeat Dialog for a similar implementation

# Title = OpenCritic Selection
# Grid with Game Name, ID, Dist
# Search Bar and Search Button to redo search if match isn't found
# Select and Cancel button to select game or cancel search respectively


