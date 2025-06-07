local TweenService = game:GetService("TweenService")

local part = script.Parent

 

local Info = TweenInfo.new(

1, -- Length

Enum.EasingStyle.Cubic, -- Easing Style

Enum.EasingDirection.Out, -- Easing Direction

0, -- Times repeated

false, -- Reverse

0 -- Delay

)

 

local Goals =

{

Transparency = 1;

Size = Vector3.new(15,1,15);

}

 

local tween = TweenService:Create(part,Info,Goals)

 

tween:Play()