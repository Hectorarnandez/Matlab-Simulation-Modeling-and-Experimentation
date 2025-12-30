% Derived from PCIe-Gen6 Specification, Tx FFE Presets, Table 8-2.

function TapWeightsOut = TxFFEPreset_PCIe_G6(TapWeightsIn, ConfigSelect)

switch ConfigSelect
    
    case -1 % User defined tap weights
        TapWeightsOut = TapWeightsIn;

    case 0 % Preset Q0
        TapWeightsOut = [0 0 1 0];

    case 1 % Preset Q1
        TapWeightsOut = [0 -0.083 0.917 0];

    case 2 % Preset Q2
        TapWeightsOut = [0 -0.167 0.833 0];

    case 3 % Preset Q3
        TapWeightsOut = [0 0 0.917 -0.083];

    case 4 % Preset Q4
        TapWeightsOut = [0 0 0.833 -0.167];

    case 5 % Preset Q5
        TapWeightsOut = [0.042 -0.208 0.75 0];

    case 6 % Preset Q6
        TapWeightsOut = [0.042 -0.125 0.708 -0.125];

    case 7 % Preset Q7
        TapWeightsOut = [0.083 -0.208 0.709 0];

    case 8 % Preset Q8
        TapWeightsOut = [0.083 -0.25 0.667 0];

    case 9 % Preset Q9
        TapWeightsOut = [0.083 -0.25 0.625 -0.042];

    case 10 % Preset Q10
        TapWeightsOut = [0 0 1 0];

    otherwise
        TapWeightsOut = TapWeightsIn;

end

end