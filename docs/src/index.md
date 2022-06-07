# AbstractPlutoDingetjes.jl

An abstract package to be implemented by packages/people who create widgets (or other [*dingetjes*](https://en.wiktionary.org/wiki/dingetjes#Dutch)) for Pluto. If you are just happy using Pluto to make cool stuff, you probably don't want to use this package directly. This package is not *necessary* to create widgets in Pluto, but it can add more advanced functionality to your widgets. See the Interactivity sample notebook inside Pluto's main menu to learn more!

![](https://media.giphy.com/media/l3vRfDn9ca5PVkHv2/giphy.gif)

# Bonds

```@autodocs
Modules = [AbstractPlutoDingetjes.Bonds]
Order   = [:function, :type]
```

# Display

```@autodocs
Modules = [AbstractPlutoDingetjes.Display]
Order   = [:function]
```

# Extras

```@autodocs
Modules = [AbstractPlutoDingetjes]
Order   = [:function, :type]
```
