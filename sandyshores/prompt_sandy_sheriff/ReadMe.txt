Check your console after installing the map for the map data link

Seating data for Sheriff (if you need it):

    [`prompt_sandy_sheriff_chair_01`] = { sit = { type = 'chair2', seats = {[1] = vector4(0.0, 0.10, 0.5, 180.0)} } }, -- prompt_sandy_sheriff_chair_01
    [`prompt_sheriff_seat_beige`] = { sit = { type = 'chair', seats = {[1] = vector4(-0.35, 0.0, 0.08, 180.0), [2] = vector4(0.35, 0.0, 0.08, 180.0)} } }, -- prompt_sheriff_seat_beige
    [`prompt_sandy_sheriff_jail_seat`] = { sit = { type = 'chair', teleportIn = true, seats = {[1] = vector4(0.0, 0.4, 0.0, 180.0)} } }, -- prompt_sandy_sheriff_jail_seat
    [`prompt_sandy_sheriff_jail_bed`] = {
        sit = { type = 'chair2', teleportIn = true, seats = {[1] = vector4(-0.6, -0.2, 0.3, 180.0), [2] = vector4(0.60, -0.2, 0.3, 180.0)} },
        lay = { type = 'bed', teleportIn = true, seats = {[1] = vector4(0.0, 0.0, 0.5, 90.0)} }
    }, -- prompt_sandy_sheriff_jail_bed