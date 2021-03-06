//
//  AppDelegate.m
//  btcbar
//

#import "AppDelegate.h"

@implementation AppDelegate


//
// ENTRY & EXIT
//

// Status item initialization
- (void)awakeFromNib
{
    // Load ticker preference from disk
    prefs = [NSUserDefaults standardUserDefaults];
    
    // Register update notifications for tickers
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handleTickerNotification:)
     name:@"btcbar_ticker_update"
     object:nil];
    
    // Pass each ticker object into a dictionary, get first updates
    tickers = [NSMutableArray arrayWithObjects:
               [[BitStampUSDFetcher alloc] init],
               [[BTCeUSDFetcher alloc] init],
               [[CoinbaseUSDFetcher alloc] init],
               [[MtGoxUSDFetcher alloc] init],
               nil];
    
    
    // If ticker preference does not exist, default to 0
    if (![prefs integerForKey:@"btcbar_ticker"])
        [prefs setInteger:0 forKey:@"btcbar_ticker"];
    currentFetcherTag = [prefs integerForKey:@"btcbar_ticker"];
    
    // If ticker preference exceeds the bounds of `tickers`, default to 0
    if (currentFetcherTag < 0 || currentFetcherTag >= [tickers count])
        currentFetcherTag = 0;
    
    // Initialize main menu
    btcbarMainMenu = [[NSMenu alloc] initWithTitle:@"loading..."];
    
    // Add each loaded ticker object to main menu
    for(id <Fetcher> ticker in tickers)
    {
        NSUInteger tag = [tickers indexOfObject:ticker];
        NSMenuItem *new_menuitem = [[NSMenuItem alloc] initWithTitle:[ticker ticker_menu] action:@selector(menuActionSetTicker:) keyEquivalent:@""];
        [new_menuitem setTag:tag];
        [btcbarMainMenu addItem:new_menuitem];
    }
    
    // Add the separator, Open in Browser, and Quit items to main menu
    [btcbarMainMenu addItem:[NSMenuItem separatorItem]];
    [btcbarMainMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Open in Browser" action:@selector(menuActionBrowser:) keyEquivalent:@""]];
    [btcbarMainMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(menuActionQuit:) keyEquivalent:@"q"]];
    
    // Set the default ticker's menu item state to checked
    [[btcbarMainMenu.itemArray objectAtIndex:currentFetcherTag] setState:NSOnState];
    
    // Initialize status bar item with flexible width
    btcbarStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    // Set status bar image and highlighted image
    [btcbarStatusItem setImage:[NSImage imageNamed:@"btclogo"]];
    [btcbarStatusItem setAlternateImage:[NSImage imageNamed:@"btclogoAlternate"]];

    // Set menu options on click
    [btcbarStatusItem setHighlightMode:YES];
    [btcbarStatusItem setMenu:btcbarMainMenu];
    
    // Setup timer to update all tickers every 10 seconds
    updateDataTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(updateDataTimerAction:) userInfo:nil repeats:YES];
}


//
// MENUITEM ACTIONS
//

// Action for menu items which change current ticker
- (void)menuActionSetTicker:(id)sender
{
    // Set all menu items to "off" state
    for (NSMenuItem *menuitem in btcbarMainMenu.itemArray)
        [menuitem setState:NSOffState];
    
    // Set this menu item to "on" state
    [sender setState:NSOnState];
    
    // Update ticker preference
    currentFetcherTag = [sender tag];
    [prefs setInteger:currentFetcherTag forKey:@"btcbar_ticker"];
    [prefs synchronize];
    
    // Update the requested ticker immediately
    [[tickers objectAtIndex:currentFetcherTag] requestUpdate];
    
    // Force the status item value to update
    [[NSNotificationCenter defaultCenter] postNotificationName:@"btcbar_ticker_update" object:[tickers objectAtIndex:currentFetcherTag]];

}

// "Open in Browser" action
- (void)menuActionBrowser:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[(id <Fetcher>)[tickers objectAtIndex:currentFetcherTag] url]]];
}

// "Quit" action
- (void)menuActionQuit:(id)sender
{
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}


//
// CALLBACKS
//

// Handles Fetcher completion notifications
-(void)handleTickerNotification:(NSNotification *)pNotification
{
    // Set the status item to the current Fetcher's ticker
    [btcbarStatusItem setTitle:[(id <Fetcher>)[tickers objectAtIndex:currentFetcherTag] ticker]];
    
    // Set the menu item of the notifying Fetcher to its latest ticker value
    [[[btcbarMainMenu itemArray] objectAtIndex:[tickers indexOfObject:[pNotification object]]] setTitle:[NSString stringWithFormat:@"[%@] %@",[[pNotification object] ticker], [[pNotification object] ticker_menu]]];
}

// Requests for each Fetcher to update itself
- (void)updateDataTimerAction:(NSTimer*)timer
{
    for (id <Fetcher> ticker in tickers)
        [ticker requestUpdate];
}

@end
