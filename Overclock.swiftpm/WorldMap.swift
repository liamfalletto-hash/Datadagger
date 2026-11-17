import Foundation

// The world, for the realistic globe. Coastlines and land come from Natural Earth
// (naturalearthdata.com, public domain), simplified for a phone.

enum WorldMap {
    static let width = 144
    static let height = 72

    /// 144 x 72 cells of 2.5 degrees, north at the top, starting at 180 degrees west.
    /// '.' deep ocean   ',' shallow sea next to land   ';' shallow sea two cells out
    /// 'f' forest   'g' grassland   'd' desert   't' tundra   'i' ice
    static let rows: [[UInt8]] = map.split(separator: "\n").map { Array($0.utf8) }

    private static let map = """
    ........................................................;;;;;;..................................................................................
    ..................................;;;;;;;;;;;;;;;;;;;;;;,,,,,,;;;;...........................................;;.................................
    ...........................;.....;,,,,,,,,,,,,,,,,,,,,,,iiiiii,,,,;..........;;;;;..........................;,,;;...............................
    ........................;;;,;..;;,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,;........;,,,,,;.............;;;........;,ii,,;;;;..........;;...............
    ......................;;,,,i,;;,,iiiiiiiii,iiiiiiiiiiiiiiiiiiiii,,;........;,iiiii,;.........;;;,,,;....;;;;;,iii,,,,;;;.;;...;,,;..............
    .........;...........;,,iii,i,,iiiiiiiii,,;,iiiiiiiiiiiiiiiiiiii,;..........;,,,,,;.........;,,,iii,;;;;,,,,,iitttiii,,,;,,;;;,ii,;;;;;.........
    ;.....;;;,;;;;;;;;;;;,tttt,,,t,,ttt,ttttt,,,,,,,,iiiiiiiiiiiiiii,;...........;;;;;,;;;;....;,ii,,,,,,,,,tttttttttttttttt,tt,,,,,i,,,,,,;;;;;;;;;
    ,;;;.;,,,t,,,,,,,,,,,,tt,ttttt,,ttt,ttttttii,;;;;,iiiiiiiiiiiii,;;...........;,,,,t,,,,;;;;;,t,,,,,tttttttttttttttttttttttttttttttttttt,,,,,,,,,
    t,,,;,ttttttttttttttttttttttttt,tttttttt,tiii,,;.;,iiiiiiiiiii,,,,;........;;,ttttttttt,,,,,,ttttttttttttttttttttttttttttttttttttttttttttttttttt
    tttt,tttttttttttttttttttttttttttttttttt,;,iiiii,;;,iiiiiii,,,,,iii,;......;,,ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
    ,,,,;,tffftttttttttttttttttttttttttt,tt,;,,iii,;.;,iiiii,,;;;;,iii,;.....;,tttttttttttttttttttttttttttttttfffffffffftttttttttttttttttttttttttttt
    ;;;;;,fffffftttttttttttffffffffffff,;,,;,fii,,,;..;,iii,;;....;,,,;...;.;,ttttt,,ttttffffffffftttttfffffffffffffffffffffffffffftttttttt,ttttt,,,
    .....;,ffff,,,,,ttfffffffffffffffff,,;;;,ffffff,;;.;,,,;.......;;;..;;,;;,fffff,,tfffffffffffffffffffffffffffffffffffffffffffffff,,,,,,ff,,,,;;;
    ......;,f,,;;;;;,,,ffffffffffffffffff,,;,fffffff,,;.;;;............;,,f,;;,fff,,fffffffffffffffffffffffffffffffffffffffffffffff,,;;;;,fff,;;;...
    .......;,;;.....;;;,fffffffffffffffffff,ffffffffff,;..............;,ffff,,fffffffffffffffffffffffffffffffffffffffffffffffffffffff,;.;,ff,;......
    ........;..........;,fffffffffggggggffffffffffffff,;...............;,,fgggffffffffffffggggggggfffffffffffffffggggggggfffffffgggggg,;.;,,;.......
    ....................;,ffffgggggggggggggggggggg,,ggg,;...............;;,ggggggfffffffggggggggggggggggggfffffggdddddddddgggggggggg,g,;..;;........
    ....................;,gggggggggggggggggggggggggg,,,;................;,,ggggggggggggggggggggg,gddddggggggggddddddddddddggggggggg,,,;.............
    ....................;,gggggggggggggggggggggg,,,,;;;................;,ggggggggggggggg,,,,ggg,ggddddddgggggdddddddddddddgggggggg,,gg,;............
    ....................;,gggggggggggggggggggggg,;;;..................;,ggggg,,g,ggggggggggggggg,gddddddgggggdddddddddddddgggggg,,;,g,;.............
    .....................;,ggggggggggggggggggg,,;.....................;,gggg,,,,;,g,gggggggggggg,gddddddgggggdddddddddddddgg,,g,;;,,g,;.............
    .....................;,ggdddddddgggggggggg,;.......................;,gg,gggg,;,;,,,gggggggggggggggddgggggddddgggggggggggg,gg,,gg,;..............
    ......................;,gdddddddggggggggg,;........................;,gggggggg,,;,,,,,,gggggggggggggggggggggggggggggggggg,;,,ggg,;...............
    .......................;,dddddddgggggggg,;........................;,gddddddddgg,ggggggdddddddddddgggggggggggggggggggggggg,;;,,,;................
    ........................;,ddddddgg,,,,,g,;.......................;,gdddddddddddgddddddddddddggdddgggggggggggggggggggggggg,;.;;;.................
    .........................;,dddddg,;;;;,g,;......................;,gdddddddddddddddddddgddddg,,gggggdddgggggggggggggggggg,;......................
    ..........................;,,gggg,;;,;;,,,;;....................;,gddddddddddddddddddg,gddddggg,,,,dddggggggggggggggggg,g,;.....................
    ...........................;;,ggg,,,g,;,gg,,;..................;,gddddddddddddddddddddg,gddddddg,;;,ddggggg,,gggggggg,,;,;......................
    ............................;,ggggggg,;;,,,g,;.................;,gddddddddddddddddddddg,gddddgg,;..;,ggggg,;,gggggg,,;;;,;......................
    .............................;,,gggggg,;;;;,;..................;,gdddddddddddddddddddddg,gdgg,,;...;,gggg,;.;,ggggg,;.;,g,;.....................
    ..............................;;,,,gggg,;;,,,;;;...............;,gggggggggggggggggddddddgdg,,;;.....;,gg,;...;,ggggg,;;,g,;.....................
    ................................;;;,,ff,,,fff,,,;;..............;,ffffffffgggggggggggggddg,gg,;.....;,gg,;...;,f,fff,;;;,f,;....................
    ...................................;;,ffffffffff,,;;.............;,fffffffffffffffffffgggggg,;.......;,gg,;..;,f,,,,;;,;,ff,;...................
    .....................................;,,,fffffffff,,;............;,fffffffffffffffffffffffff,;........;,f,;..;,,f,;;;,f,;,,;....................
    ......................................;;,fffffffffff,;............;,,,,,,,,ffffffffffffffff,;..........;,;..;,ffff,;,ff,;;;..;..................
    ......................................;,ffffffffffff,,;;;..........;;;;;;;;,ffffffffffffff,;............;....;,fff,,fff,,;..;,;;;;..............
    ......................................;,ffffffffffffff,,,;................;,fffffffffffff,;...................;,ff,,fff,f,;;,f,,,,;.............
    ......................................;,fffffffffffffffff,;...............;,ffffffffffff,;.....................;,ff,,f,,f,;;,fffff,;............
    ......................................;,ffffffffffffffffff,;...............;,fffffffffff,;......................;,ff,,;;,;..;,,ffff,;...........
    ......................................;,ffffffffffffffffff,;...............;,ggggggggfff,;.;.....................;,,;;..;...;;;,g,gg,;..........
    .......................................;,ffffffffffffffff,;................;,gddddddgggg,;;,;.....................;;.....;;;,,,;,,,,;...........
    .......................................;,gggffffffffggggg,;................;,gdddddddddg,;,g,;..........................;,,,ggg,gg,;............
    ........................................;,gddgggggggggggg,;................;,gdddddddddg,,gg,;........................;;,gggggg,gg,;............
    .........................................;,,dggggggggggg,;.................;,dddddddddg,;,gg,;.......................;,,gddgggggggg,;...........
    ..........................................;,dggggggggggg,;.................;,ddddddddg,;,gg,;.......................;,ggdddddddddddg,;..........
    ..........................................;,dggggggggg,,;...................;,dddddddg,;,gg,;......................;,gddddddddddddddg,;.........
    ..........................................;,dgggggggg,;;....................;,gdddddg,;.;,,;.......................;,gddddddddddddddg,;.........
    .........................................;,ggggggggg,;......................;,gdddddg,;..;;.........................;,gddddddddddddddg,;........
    .........................................;,ggggggggg,;.......................;,gdddg,;..............................;,gdddggggddddddg,;.........
    .........................................;,gggggggg,;........................;,gggg,;...............................;,gggg,,,,ggdgggg,;.......;.
    .........................................;,dddggg,,;..........................;,,,,;.................................;,,,,;;;;,,gggg,;.......;,;
    ;.......................................;,gdddggg,;............................;;;;...................................;;;;....;;,gg,;......;;,g,
    ;.......................................;,gdddg,,;..............................................................................;,g,;.....;,,gg,
    ........................................;,gddd,;;................................................................................;,;.....;,gg,,;
    ........................................;,gdd,;...................................................................................;......;,g,;;.
    ........................................;,gdg,;...........................................................................................;,;...
    ........................................;,ggg,;............................................................................................;....
    .........................................;,gg,;.................................................................................................
    ..........................................;,,;..................................................................................................
    ...........................................;;...................................................................................................
    .............................................;;.............................................;;;.................;;..;;...;;.;;;.................
    ............................................;,,;.....................................;;.;;;;,,,;;;;;...;;;;;;;;;,,;;,,;;;,,;,,,;;;;;;;..........
    ..........................................;;,ii,;...................;;;;;;;;;;;;;;;;;,,;,,,,iii,,,,,;;;,,,,,,,,,ii,,ii,,,ii,iii,,,,,,,;;;;;;....
    .......................;;;;....;;;;;;;;;;;,,,ii,;.................;;,,,,,,,,,,,,,,,,,ii,iiiiiiiiiiii,,,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,,,,,,;...
    .............;;;;;;;;;;,,,,;;;;,,,,,,,,,,,iiiii,;............;;;;;,,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,;..
    .......;.;;;;,,,,,,,,,,iiii,,,,iiiiiiiiiiiiiiiii,;..;;;...;;;,,,,,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,;..
    ......;,;,,,,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,,,;..;,,,;;;,,,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,,;...
    ...;.;,i,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,,,,,,,;;;,iii,,,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,;;...
    ;;;,;;;,;,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,,,iii,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,,,,;;;
    ,,,i,,,,,,,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii,,,
    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
    """

    struct Point {
        let lat: Double // radians
        let lon: Double // radians
    }

    /// Simplified coastline rings: uint16 ring count, then per ring a uint16 point count
    /// and that many (int16 longitude, int16 latitude) pairs in hundredths of a degree.
    static let coast: [[Point]] = decodeCoast()

    private static func decodeCoast() -> [[Point]] {
        guard let data = Data(base64Encoded: coastBase64, options: .ignoreUnknownCharacters) else { return [] }
        let bytes = [UInt8](data)
        var offset = 0
        func u16() -> Int {
            guard offset + 1 < bytes.count else { return 0 }
            let v = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
            offset += 2
            return v
        }
        func i16() -> Int {
            let v = u16()
            return v >= 32768 ? v - 65536 : v
        }
        let degree = Double.pi / 180
        var rings: [[Point]] = []
        let count = u16()
        for _ in 0..<count {
            let n = u16()
            var ring: [Point] = []
            ring.reserveCapacity(n)
            for _ in 0..<n {
                let lon = Double(i16()) / 100
                let lat = Double(i16()) / 100
                ring.append(Point(lat: lat * degree, lon: lon * degree))
            }
            rings.append(ring)
        }
        return rings
    }

    private static let coastBase64 = """
    dAAGALvovOCA6Fzgz+Zk4BvmpuDU55ngU+jl4AQAz8Hy4A/B5eANwEzhA8Fi4QcAXe6D4djuWOET773gSOxZ4NjqgeAV7Ofg/uyD
    4QQAp9BK46DRTOMJ0Q/jGtA64wMA9M5M443PJeNIzk7jBQBW2efjMdrl42zarOOi2K7jB9jr4woAQ+VI5CLlz+M85K7jueOw4+rj
    1+MF47vjs+IC5NnjMeT649nkj+QY5ZEAG+nx5sbnsOaH52zmvOcl5hnnBuZZ5nXlUOf15NvnYOQ96Dbj3eaa4mzkEeLU4QniOuOR
    4Y/hYuGG4RLhkOKm4K/o0t9C6X7fkOwT4Efv8N8T8Djg2fSe4Gf0CuEU8vbgBvJm4TPyfOG49A3iKPmn4t755uL7+Q3jkfkl4/f5
    beMz+7jj+vsp5Br9/uNR/UvkTv4W5L7/LeTp/wTkBgOz5LkDp+Q6BFXkPgWr5OkFgOSGB7Pk0Qhi5JUKeuR/DMrkOw0+5RkPvuRN
    FUrmBBY75vIWt+X/F3XlBRmr5ekad+U3G/XkfRqJ5PsaZOSLGu/jSxvG474b1+PaHLXkVB7e5OceT+VWIL/l4yHF5V8iI+YHI8Xl
    aiWt5fQmu+UrKGTmeinb5WAsROYoLfLlzy655SIwCOZQMuzlpDQj5sM0feayNdnl1Tjc5Uk5euUkOknlkjsZ5UQ8OOUdP27kW0FV
    5OFC/uMhQjrj4UDy4uU/OOLdP+XhWkB24TxBPeExPxThaz5h4CxCQd9QRuneUEbY3LC52NywueneDroi3+K7+96dvTzfQcKn3vvF
    j94ZyMjeL8j33gHET99KxPTfvMJS4CfFOuDOxp7gl8UA4VPDHuFDwoXhI8L34ePExOHuxiDi5MaO4mXHoOKgx37iL8v64j7R6OJ+
    0zXjItTR4q/YluLk2MHi8dcN44DXouNe2j7jz9xc4yXdqOMt4CfjouBv47/iJeOv5bDju+UE5DrlxOSp5WHliuWz5WTnwOZr6Unn
    pukv5wsAieX36pfmoupq5nDq2OWO6mHlR+r15FLqxuO26tbiXOs55OHq6eR86zHlcOsFACHpCuxx6d3rU+m660rokusY6L/rBAB0
    G5Xs2hqO7O4aAu2NG9bsBgDMOBHw7TkI8Mc5H+8NOf3uiDjs74o4GvAMAJZDBPARRNnvd0MP75xD3+75QrjupkIR7iVCyO0cQfLt
    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
    dxCbAyoQVgOCEKsDzRAMADc4QRHEOFYR2jjmEEY4yxDuN2gQUTesEBs3PhCsNj0QnjagEM827RA6N/MQdTfLEQUAIucvEsfnJBJx
    5/UR8uYfEv/mYBIFAMHP8xLqzhMT+s2HE9zN1RPgzqYTFgAT6s0T0Ol1ExLqlxNV6oITMupfExzrPRP96vQSQ+sFE2/rkhJF6zoS
    1upJEtDqpxJc6lASIOpUEmfqgxIH6psS2eiYEgjp2RLd6PQSmOnQEy3qKxRb6icUBgApzBwVicwkFWvMshTCzGIUB8zdFPrLKRUO
    AB040xOBOCIT7TdDE7A3shIROEwSDzgGEsM3QhKBN/URijfnE083ShRYN9IUtTcAFY03LxW5Nz0VBgBZ/WoUGvw+FGv8phQ3/AwV
    X/2NFcr9TxUEAPUEuRW5BGgVQgTKFdUE6xUFADvEUBbXwykWlcNyFmjEnhaSxH8WFwDT/ugWaf57Fjz/iBbI/t0VL//XFS8ArRSo
    AJoUaQA9FJEACRTz/YQTvv2YE6v+FxTx/U8UWv5uFCP+pBQ2/uYUy/7cFNn+FhUc/mcVB/7KFdH9mxWZ/S8WC/7nFgMAUr9nF5a+
    hRdJv40XAwAJ4UgY4uATGJzgOhgEAALgfxiN30gYMd9lGHvfkxgEAOu86hgbvroYx72aGP28vBgJALzephm24OUYXeDFGInfChmY
    3qEYdd7cGO7d0hhF3gQZdN6uGQ0AVfr2GT76tRmv+nEZtvjOGBz3/Bh+9ygZpPZZGVH3ihl/9qEZw/biGVv38Rn2960ZjvjkGQUA
    XeI7Gu3hNhrU4WcaWuKtGqriZhoQAKO7Ahrmu+oZz7syGt68IxqivcYZm7yQGXC8GRkru4gZVLqLGR66rhkzutMZvLm7Gem5jBmw
    uWIZsLnwGqu7QRoEAKPa/xpl2twaBNkcG6LZZhsDAFBGqxvRRcYbUEbwGwQAM7qxG7C5qxuwufAborrXG1wBodwmG6HcwBom3Q4b
    nt3OGoDdgxrh3UAakt7eGpjeTBu63zYbQOAEG/zfnRpC4GgaNeA3GnLf8Rl/3gAa5N1OGeHcAxmS3NkYi9yYGJzbOhgw28oXBNsH
    F5bb9hby200WftxgFsvemhXd34sV7N/QFMngARRM4YgU0eBbFXHhihUa4hUWzuGtFlTh+BbK4WEXfeFYGCjjZBgf5OIX0eTaF+/k
    CBeT5b0WJOb1FsbmkhcE6EEW3OcCFpvpVxXC6QIVOOrPFEDqXxSN6KATEOafEzrkShIv5d4SluY7E+/mChOQ5scS0eYQEvjn7BFc
    6F0SpOjwEXjmAxEs5goRKOZfEdXmsRHG5aIR2OWBEWPkzxBV5IoQq+REEDXj/Q/l4/0PHePrD73iNg9/4m4PruIAD1biig5s4tIO
    LeJLDy/i4A7w4e8OMuLQDmvi4w064EgMPeC8C7rggAqa4NkJS+DYCRXgGwqi3+UKm99eCybfwQvB3pQLQN7gCyrd2AsA3coLJt1x
    C8ncYAtX25sLRdoPC/fZsgoO2hsKxdnECGPajAcd2xYHDNxOB4vciAe83DQI/91qCBPeJQiw3SIHgt06B3zddQZD3TUGzt5ABmvf
    9wVD31YE49+EAzDgbwPr4MED/OFgA3HisAO94lQEU+NjBPnj3AQ25LsE5eN2BP7jiwNA5NoDHORJBJjkcgSu5MAEXeUfBCHmKQSn
    5vAD4OYoBNTnMAR/5xIEoefjAz3oqgNN6FoD6uggA63pVQLs6kAC9OukAUXsvgB77K4AMuwWAFHs+P8C7ej/Bu2E/1Ltxv917mX/
    lu7z/grvEv9i8OH+dvEe/hjy/f1v8iL9R/J8/OXw5vqp8AX5AvBu95nvB/eP7uH2Y+1H9g7t5PXn7M30++qQ8grqYvIt6cHyJumN
    8qXpN/LR6ZbxcekW8d3o4PCm59Xwuecc8H3n+e+Q5vbvnuaS7xjnlO8252DviuYC72PmaO635TXumuXq7VzmjO055jPt/uQv7GHl
    jetT5FbrQ+T56rnilut34v3sC+Oq7XTix+3T4iDu9eLG7mTjo+6Y43LvVeOM7zbjD+/34h7vZuOq8EHjfPFr44DxGORW8xPkuvRN
    5DT1mORI+IPk1fgW5Dj5T+JH+tjgMf1D4Jr9Y+DH/TPgJv7X4Pb+X+Af/2Pglv+34E0AMuGKAF3hBwHf4YEBduFAA+zgfQOQ4CkD
    wODzAmfg0gJW4A4DYd9NA87e8QPB3rwDit7hA4XeVQTB3QsF090yBV3ccQUD21QGSNodBpLXJQfL1ssH4dZeCJXW5QhS1f4JT9VU
    CinUTwvN0y0MhdNVDCrTbAw108gLZtRqCsbUfglD1SAJBdXqCC7Uqgki1CkKDtPUCmjTKQvg0owLLtLpDLTRSw3i0IUNaM+/D1vP
    tRCaz8gRS8/SEujPxBId0GYSBNAkEzjO2xMPznEUj82cFH3N7BRzzK4VoMu0FqHKvRZdyUIXicbIFxrGsxcuxm4XvMQcF9vEuRdF
    xdcXKsXwF9bDLxcfxP4WwcO3Fh3C3xWhv0AVZMJ9FqjCBBfewdIWXMETF7vA6xbFwEsXAsBcFxy/Bhi4v6sYM8HpGOjAKBkywU8Z
    kL8tGVW+pxnBvwIaE8ACGgXA0BnYwNQZ3L60GhS/6BpDwBkbwcB5G9bC4Bu2w54b6cdnG67K6hpNzWsbkc1CG/LNiBvgziQbZs9o
    G3PPHBuN0EQb+9LrGoLTuBr20oYaDdWOGnjVUhrl1YUaf9WvGr/V0RqJ1uAaX9htGozZehqA2bga2dnKGnTaqBpz2kkas9qZGgTb
    lhox2/saUdphG1nazxvP2hgcuNvcG0Dcaxvn2zobGgBn05AcNdNhHBTUgByf1E0cENWAHL3V/Rvv1SccqNWNHGTWjBzU1mMcMte7
    G47YWhuD2C4b39cmGx/YABv919sanNYGG73Txhql0gUbKtJUGxbUfRvy0Y4bvdGzG6XS2xtc0fQb9dFnHAMALteuHNbWbBw61rIc
    BQAu4o4c8+BqHGjgpRyd4NAcguHFHCsAMN6UHH/eVRzb3qYc2N/PHITgaBx14CYcmuFrHAHjCRwO490byOP0G3nlZBvX5QcbH+XY
    GtfnHhoI52QZ8OXvGW7l4hli5akZfOYmGb3mwxib5nsYIuXnGCfmMRhC5JMYxeJEGaXhFxlQ4TkZkuGDGRzjkRn74rUZn+NIGoPj
    dRr54ekaOeIDGyjhaRs94D4bXN2BGwndpBtx3dIb49zSG8PcOBx33boced7UHAoAzNjYHPbZ0BwQ2rMcs9mDHEraWBw42v4bNNng
    G/bXUxzE2GccVtioHAMAGDiZHKI2qRx+N9ocBgCY220cLdsiHLvaJhx+2rAcFtv1HKXc2hwIAPLQ5Bvrz7Ibz84THJbPyBw0zwUd
    FNL7HOHStBxu0VQcAwDhOlQdbjotHRQ5XR0EAG/bSh042yMdLtpFHfPajR0GAK04hB1eODodSDYlHYE1Zh23NasdOza+HQUAhtn4
    HdLZyh2o2Uwd9teEHe/X0h0MALvVxB2k1q0dttZ8HXnWTR2S0w8dhdMwHVXUXB0F0mId7NLgHWXVex3W1NsdMtX/HRAAehagG/gU
    pBsoFOsbGhQhHIAUNxx8FG0cQxXDHOcUzxzWFScduxVUHeUXyR2gGg4e5RrmHdgWBx2mFUUcuhXyGw0ABNseHjfc/h2O3N0dd9y3
    HSndiR1P4JMd0eBEHZHdDx3m2zwdt9ukHVPb0B0Q2vsdNdokHgUAnNJVHo7SCB5B0uUdA9C8HXrRRx4UAskpER7kKeAdZCv3HZUs
    oR19LG0dvCr6HCYs5hxZLKYcJS3PHCAwgRwmMM4cmjG9HDsyiBxpMkgcLjIeHEkzpxupMxAcSjTjG6M27RtbNkoc3zZ1HGY6NBzB
    O6wbHD6vG28+hRtjPjwb3j4gG5BBLhs+QtUaukL1GmlCNRuVQmIbxEUcG1BG8BpQRmIZTUU9GR1GcRjYQxUYiUJkF/pBqRf2QFsX
    yECAF+I/YxdKP8AWvz+CFrI/8BVVP+wVKj+ZFVQ/bhWlPjoVgj7IFO09sBTPPUoUPz3tE7c8ohXnPC0WQT2XFtw9rhbvP+IXP0Bv
    GMY/ZxiKPxQYjD6mFzo+IRg4Pf8XPjxYF5A8GxcXO/YWHjs+F4I6ThcGOhwXjDcQF8k0YRVmNVQV+DUAFaY2KxU3N70UOjdoFOw2
    BBS2Nu0S/jUXEq809BAqNLkQrDPoEMUyYhCrMvgP0TGID8MxUQ+SMl4ObTK0DWkxbw1EMVkOjjFpDkkxvw63MOMO9DBzD4swmQ9J
    LzIPuS/KD4Qv/w9+LlUPHC5QD+ktIg9zLqEOwi6EDjIvyw7ML6EO3C9tDk4vUQ6LLqMN9y5sDZ8vYQydLxcMXi/8C7EvpwuILwcL
    US/+CloulwlFLeYIRytcCCQr8gftKuwH6ipcCGQqfAhcKbcHRilyB4gq+AW2Kj8FqCqPBBQpXAMMKeADbignBBMowwRjJ+8Ecic9
    BRonPQXCJpwDAyeZAz4n5wI4KCgCtyiBAHAoewCbJxQBGSeGAnomRgNqJgsDlCZ4BPQlnQZBJSMGyyREBtgkHQe2I+UIWiPpCEMj
    iAj6IWYIyiHfBzohnAcbIHgGYB82BjIfDARKHh0D6x16A7kcPwZfHFgIhxsoCAQboQg0G8UIFxvsCFgaWgntGe8JBhjMCWwWDgoR
    FpoKYBVYCiAU4wqUE8cLvRK2CxET0QqXE20K2ROrCe0TKQonFBQKOxRiCRkVbAkEFlAKNRZ4CfEWNQldF7cIlxboB4kWZgeXFbsG
    dxRmBmEUGAYEE3gF/BDwBKQQ8QWpEI0GSg9RCAkPQQmkDn0JuQ32CocN9gqkDYYLQA3NCqoMqQvxDVkJ4Q0GCWcOmAikDkUHAQ8I
    B1cPOAbsENcEsBCWBG0RFAT3E7IE8RMoBKYSpgG6D//+UA8s/igPeP1oD1T9Tw+v/NAPy/vuD0P6aQ94+Z0OIfmXDUb46Q299rkM
    8/XcDML1lAzF9AYLM/MSCr7y0QjG8qoHZvIuB6ryAQdD8x4HovPxBWv1kgVd95sE8fiaBNX5UwVM+1kFz/uoBAj+cAOR/9QDMwGs
    A3UBUgPdAU4CqgGxAXMCuwBmAjz/1wEv/gUCEP2yAXz84wEl+9YCNPpABIP5wQR5+VAFHvnBBZL5Tgax+RMHX/mNCFz6QQpE/LEL
    K/wuDF78uAxN/VMNr/34DSf/vQ2TAE0OtwOXDv0Diw76A1gOVgRqDiQEOQ5GBPINCgQzDfUFmwwjBkIMdQfTC9UHGwzdB5gMagjU
    DEsLDwwaDFQMfAwVDDENGQyADVMMEA6IDSAOUQ6PDWAOswwbDmIMUA6aCx4OzApSDkgK7Q54CjsPOQpqD6gKyg9CC84PbAsaECsM
    DRAXDWoQvQ1sEPsO/w/FDwUQShBkEDEQqRBUDqwR7w4QErcOOBJID3YSqA0TEq4N1RFFDsMRMQ6fETwNVBEFDWgRGw2XEa0MtREf
    DekRAg0AEgMMMhKTC5gRRAuLEc8KohBBCwkQygoEEEwKrw8uCvIPvQn/D0MJ5Q+JCa0PVgmcD9cIug9kCbYOCAnQDiUJnQ7mCJMO
    Cwk6DskIOQ53CGUOQAj3DpUHuQ+iB0wQQgb/ENIFnBFzBYARcgXPESIF3hHRBLoR6wQ5EeoFZBA5BmQQNQY6EDgHsQ8lB40PlwbM
    D20GjA+1BmYPqQYyD0oG1w4gBs8OSwY4DwUGpQ+7BEoQGwTFEPwDKBF5A1URjQLZEDYB1BAwAV0QUQAFEOT/Ww8LACIPKf9TDkv+
    VA7m/QsOdP1uDob8Zw6M/PMOR/wiD5P87A9V/M8Q4vwXEUL/9hB2/zIRif/5Edj+lRI//rwSNf4EE17/ABM//3ITnf9HE4YAlROk
    AOcTfwEqFNcBvRQsA+kUcAMaFSwDsBVWA08WIgSNFgEEORZDBA4WxQOrFeIDVBVGBBkV5ARHFYQFABXiBm0VrgdDFU8IjxU9CC4W
    bghtFswIjxYcCUUWbAlHFosJzhYnCeUWHgkfF+4KPBdgC3MX9wqiF+8IYRdUCLgXaggbGDoIdRhqCK8Y7AlvGVYJyRmqCKwZSQhn
    GVkIKRn5BoMYsAb2F1cHeBf7BgcXkwbwFjQG6hW7BfQVggWlFQ4FoBUMBDsXRgPHFsECsBY3AuMW8wE1GB0EMRnEBX0afgdGG/4I
    bBuXCb8bAQvPGzkMhRu5C2sbJgwsG40MTxu9D4kaERAXGqIP4xn+DsgZ9gwHGpkNvhmmDSkZdQ7xGEQOThmGDnIZdw80GcwPTBmI
    D5YZcRD4GSsRzxllERQaEhFPGkMRixr5EMkaERKpGkoScRrMEWUazBEtGhsSCxr8FOYaRxXhGuUUpBr4FugaahesGtwX7hpzFygb
    pxdJG8MamRoGG84aJRohG0YaURsNGr8bxhoZHAgbdBxbHG4ccBw2HBEc5RtvHH8bWBz2GsccuRrYG+gZShzZGVEdeBoXHbEaRh3z
    Gtgc+xrAHDMbEB2XG44c6RtBHSwcKh1zHJAdPhxpHd4b1B3LG6YdExxOHjsc1h8HHH0fWhxzH8Uc6iHiHJkhFh0NIlgdXCfbHdcn
    MR7DKFoebyk5HucoIR4EAPXUWh6n010eitSHHhfVeB4FAKgJaR4ZCFgeXghyHiEIkR7wCKUeAwAq1bQeCtShHnLUzR4EAJHafh6s
    2YAeednPHqzaoh4FAOrYmB4R2W8e6taeHkvXvB7L1voeBAAMKZce2CZwHuEn/x4pKb8eCgAhByIfagjYHm8HsB6wBgEeNwb9HWAF
    Oh67BV4eYgTPHhQEHR+jBkUfBADxCWkftQpGH/4IBB/JBmAfBgD6E3cflxJBHyoSWR9jEngfhRF7H4wTnB8FAAon0B4ZJeAeniNi
    H3olvR8jJyofDAAC3h4fe97+Hojcjh6425oeTdvDHp3bAh/n2gEfOdpQHyrboh/+2rkf59u+H7PdYB8bAD7ldyDT5ywgkuXWH2zm
    1x8y5Cwf9eH8Hn/i8B464t4ejeKtHtjgKR6T4f4diODCHQvd3x3+3A8et90mHobdbh7O3koepN2dHsPe/x4L3lkfB+BuH8jddB85
    3P0fmt5JIILfKCDO314gBeF5IEkAavWgINv3USC88wogDvcRIGH37R/z9rMf1/n/Hzv7wR8r+FIfE/lNH074wx5R+FQeyfgTHoj3
    7x1B+LodWPhlHe33XB1v+AYdkff+HAX41hzk97Icy/ajHEr3MhxR9kEcW/frG4H3mhvO9ocbBvbnGyj2oxu09W8bRfdlGyn1vxqW
    85wapPIMGnPwkhnp78wYRu98GG7vLhgO73oXJu3GF9Xr2xiU63YZCuvSGS7rHBrr6j8aTuu0GuTr2Roh7FEbHusQG6TqMRvE6qob
    7euRGzHq/Rug6lscHemAHRHouh0+5bYdHOQVHuzlOh5e43webOOjHlXmAx985igfbuVMH7HnxB+H5/Efp+kbIEjr/R9R7DQgnO7m
    H67tHCC87UcgC++DIA==
    """
}
