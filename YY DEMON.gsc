// Simplified Call of Duty Mod Menu
// Core features only - easier to understand and modify

main()
{
    level thread custom_init();
}

custom_init()
{
    level endon("game_ended");
    level thread custom_onPlayerConnect();
    custom_initDvars();
}

// Initialize all console variables (dvars)
custom_initDvars()
{
    if (!isdefined(level.init_dvars))
    {
        level.init_dvars = 1;
        
        // Movement
        setdvarifuninitialized("move_speed", 1.0);
        setdvarifuninitialized("super_jump", 0);
        setdvarifuninitialized("god_mode", 0);
        setdvarifuninitialized("noclip", 0);
        
        // Weapons
        setdvarifuninitialized("inf_ammo", 0);
        setdvarifuninitialized("give_weapon", "");
        setdvarifuninitialized("no_recoil", 0);
        
        // Visual
        setdvarifuninitialized("nohud", 0);
        setdvarifuninitialized("nvg", 0);
    }
}

custom_onPlayerConnect()
{
    level endon("game_ended");
    
    for (;;)
    {
        level waittill("connected", player);
        player thread custom_onPlayerSpawned();
    }
}

custom_onPlayerSpawned()
{
    self endon("disconnect");
    level endon("game_ended");
    
    for (;;)
    {
        self waittill("spawned_player");
        
        if (isbot(self))
            return;
        
        // Start watching for dvar changes
        self thread custom_watchMoveSpeed();
        self thread custom_watchSuperJump();
        self thread custom_watchGodMode();
        self thread custom_watchNoclip();
        self thread custom_watchInfiniteAmmo();
        self thread custom_watchWeaponGive();
        self thread custom_watchNoRecoil();
        self thread custom_watchHUD();
        self thread custom_watchNVG();
    }
}

// ============================================
// MOVEMENT FEATURES
// ============================================

custom_watchMoveSpeed()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevSpeed = getdvarfloat("move_speed", 1.0);
    
    for (;;)
    {
        newSpeed = getdvarfloat("move_speed", 1.0);
        
        if (newSpeed != prevSpeed)
        {
            prevSpeed = newSpeed;
            self setmovespeedscale(newSpeed);
            self iprintln("^2Movement Speed: ^7" + newSpeed);
        }
        wait 0.1;
    }
}

custom_watchSuperJump()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevValue = getdvarint("super_jump", 0);
    
    if (prevValue == 1)
        self thread custom_superJumpLoop();
    
    for (;;)
    {
        newValue = getdvarint("super_jump", 0);
        
        if (newValue != prevValue)
        {
            prevValue = newValue;
            self notify("stop_super_jump");
            
            if (newValue == 1)
            {
                self thread custom_superJumpLoop();
                self iprintln("^2Super Jump: ^7ON");
            }
            else
            {
                self iprintln("^1Super Jump: ^7OFF");
            }
        }
        wait 0.1;
    }
}

custom_superJumpLoop()
{
    self endon("disconnect");
    self endon("death");
    self endon("stop_super_jump");
    level endon("game_ended");
    
    for (;;)
    {
        if (self jumpbuttonpressed() && self isonground())
        {
            velocity = self getvelocity();
            self setvelocity((velocity[0], velocity[1], velocity[2] + 400));
            wait 0.3; // Cooldown
        }
        wait 0.05;
    }
}

custom_watchGodMode()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevValue = getdvarint("god_mode", 0);
    
    if (prevValue == 1)
        self thread custom_godModeLoop();
    
    for (;;)
    {
        newValue = getdvarint("god_mode", 0);
        
        if (newValue != prevValue)
        {
            prevValue = newValue;
            self notify("stop_godmode");
            
            if (newValue == 1)
            {
                self thread custom_godModeLoop();
                self iprintln("^2God Mode: ^7ON");
            }
            else
            {
                self.maxhealth = 100;
                self.health = 100;
                self iprintln("^1God Mode: ^7OFF");
            }
        }
        wait 0.1;
    }
}

custom_godModeLoop()
{
    self endon("disconnect");
    self endon("stop_godmode");
    level endon("game_ended");
    
    self.maxhealth = 999999;
    self.health = 999999;
    
    for (;;)
    {
        self waittill("damage");
        self.health = self.maxhealth;
    }
}

custom_watchNoclip()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevValue = getdvarint("noclip", 0);
    
    if (prevValue == 1)
        self thread custom_noclipLoop();
    
    for (;;)
    {
        newValue = getdvarint("noclip", 0);
        
        if (newValue != prevValue)
        {
            prevValue = newValue;
            
            if (newValue == 1)
            {
                self thread custom_noclipLoop();
                self iprintln("^2Noclip: ^7ON");
            }
            else
            {
                self notify("stop_noclip");
                self custom_noclipDisable();
                self iprintln("^1Noclip: ^7OFF");
            }
        }
        wait 0.1;
    }
}

custom_noclipLoop()
{
    self endon("disconnect");
    self endon("stop_noclip");
    level endon("game_ended");
    
    self.noclip_obj = spawn("script_origin", self.origin);
    self playerlinkto(self.noclip_obj);
    
    for (;;)
    {
        movement = self getnormalizedmovement();
        angles = self getplayerangles();
        
        forward = anglestoforward(angles);
        right = anglestoright(angles);
        
        moveVec = (movement[0] * forward) + (movement[1] * right);
        
        speed = 10.0;
        if (self sprintbuttonpressed())
            speed = 30.0;
        
        self.noclip_obj.origin = self.origin + (moveVec * speed);
        
        wait 0.05;
    }
}

custom_noclipDisable()
{
    if (isdefined(self.noclip_obj))
    {
        self unlink();
        self.noclip_obj delete();
        self.noclip_obj = undefined;
    }
}

// ============================================
// WEAPON FEATURES
// ============================================

custom_watchInfiniteAmmo()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevValue = getdvarint("inf_ammo", 0);
    
    if (prevValue == 1)
        self thread custom_infiniteAmmoLoop();
    
    for (;;)
    {
        newValue = getdvarint("inf_ammo", 0);
        
        if (newValue != prevValue)
        {
            prevValue = newValue;
            self notify("stop_infinite_ammo");
            
            if (newValue == 1)
            {
                self thread custom_infiniteAmmoLoop();
                self iprintln("^2Infinite Ammo: ^7ON");
            }
            else
            {
                self iprintln("^1Infinite Ammo: ^7OFF");
            }
        }
        wait 0.1;
    }
}

custom_infiniteAmmoLoop()
{
    self endon("disconnect");
    self endon("stop_infinite_ammo");
    level endon("game_ended");
    
    for (;;)
    {
        self waittill("weapon_fired");
        
        weapons = self getweaponslistprimaries();
        foreach (weapon in weapons)
        {
            self givemaxammo(weapon);
            self setweaponammoclip(weapon, 999);
        }
    }
}

custom_watchWeaponGive()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevWeapon = getdvar("give_weapon", "");
    
    for (;;)
    {
        newWeapon = getdvar("give_weapon", "");
        
        if (newWeapon != prevWeapon && newWeapon != "")
        {
            prevWeapon = newWeapon;
            self customGiveWeapon(newWeapon);
            setdvar("give_weapon", "");
            prevWeapon = "";
        }
        wait 0.1;
    }
}

customGiveWeapon(weaponName)
{
    weapon = getcompleteweaponname(weaponName);
    
    if (!isdefined(weapon))
    {
        self iprintln("^1Invalid weapon: ^7" + weaponName);
        return;
    }
    
    self takeallweapons();
    self giveweapon(weapon); // built-in
    self switchtoweapon(weapon);
    self givemaxammo(weapon);
    
    self iprintln("^2Weapon Given: ^7" + weaponName);
}

custom_watchNoRecoil()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevValue = getdvarint("no_recoil", 0);
    
    if (prevValue == 1)
        self thread custom_noRecoilLoop();
    
    for (;;)
    {
        newValue = getdvarint("no_recoil", 0);
        
        if (newValue != prevValue)
        {
            prevValue = newValue;
            self notify("stop_no_recoil");
            
            if (newValue == 1)
            {
                self thread custom_noRecoilLoop();
                self iprintln("^2No Recoil: ^7ON");
            }
            else
            {
                self player_recoilscaleoff();
                self iprintln("^1No Recoil: ^7OFF");
            }
        }
        wait 0.1;
    }
}

custom_noRecoilLoop()
{
    self endon("disconnect");
    self endon("death");
    self endon("stop_no_recoil");
    level endon("game_ended");
    
    for (;;)
    {
        self player_recoilscaleon(0);
        wait 0.05;
    }
}

// ============================================
// VISUAL FEATURES
// ============================================

custom_watchHUD()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevValue = getdvarint("nohud", 0);
    
    for (;;)
    {
        newValue = getdvarint("nohud", 0);
        
        if (newValue != prevValue)
        {
            prevValue = newValue;
            self setclientomnvar("ui_hide_full_hud", newValue);
            
            if (newValue == 1)
                self iprintln("^2HUD: ^7Hidden");
            else
                self iprintln("^2HUD: ^7Visible");
        }
        wait 0.2;
    }
}

custom_watchNVG()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    
    prevValue = getdvarint("nvg", 0);
    
    for (;;)
    {
        newValue = getdvarint("nvg", 0);
        
        if (newValue != prevValue)
        {
            prevValue = newValue;
            
            if (newValue == 1)
            {
                self nightvisionviewon();
                self iprintln("^2Night Vision: ^7ON");
            }
            else
            {
                self nightvisionviewoff();
                self iprintln("^1Night Vision: ^7OFF");
            }
        }
        wait 0.1;
    }
}

// ============================================
// USAGE INSTRUCTIONS
// ============================================
/*
HOW TO USE:
-----------
Open console (~) and use these commands:

MOVEMENT:
/move_speed 2.0        - Set movement speed (1.0 = normal, 2.0 = double)
/super_jump 1          - Enable super jump (0 to disable)
/god_mode 1            - Enable god mode (0 to disable)
/noclip 1              - Enable noclip (0 to disable)

WEAPONS:
/inf_ammo 1            - Enable infinite ammo (0 to disable)
/give_weapon ar_mike4  - Give weapon (use weapon name)
/no_recoil 1           - Remove recoil (0 to disable)

VISUAL:
/nohud 1               - Hide HUD (0 to show)
/nvg 1                 - Night vision (0 to disable)

EXAMPLES:
/move_speed 3.0        - Run 3x faster
/super_jump 1          - Jump really high
/god_mode 1            - Can't die
/inf_ammo 1            - Never reload
*/
