% --- Load Head Model ---
load('HArtMuT_mix_Colin27_small.mat');

% --- Configuration ---
epochs = struct('n', 100, 'length', 1000, 'srate', 1000); 

% --- Load Forward Model ---
forwardModel = lf_generate_fromhartmut('mix_Colin27_small', 'montage', 'S64');

% --- Define Muscle Artifact ---
muscleSignal = struct('type', 'erp', ...
                      'peakLatency', 50, ... 
                      'peakWidth',  30, ...
                      'peakAmplitude',  10 + 5*randn(), ...
                      'peakLatencyDv', 10, ...  
                      'peakWidthDv', 6, ...        
                      'peakAmplitudeDv', 2, ... 
                      'frequency', 20 + 5*randn(), ... 
                      'probability', 0.2, ...
                      'probabilitySlope', 0); 
muscleSignal = utl_check_class(muscleSignal, 'type', 'erp'); 

% --- Define Blink Artifact ---
blinkSignal = defineERP(50, 50, 30 + 10*randn(), 0.4); 

% --- Define Cognitive Components (P3a, P3b) ---
p3aSignal = defineERP(300 + 20*randn(), 150, 8 + 2*randn(), 1);     
p3bSignal = defineERP(400 + 30*randn(), 150, 8 + 2*randn(), 1);    

% --- Define Background Noise ---
noiseSignal = struct('type', 'noise', 'color', 'brown', 'amplitude', 0.1, 'probability', 1, 'probabilitySlope', 0);
noiseSignal = noise_check_class(noiseSignal);

noiseSignalBrain = struct('type', 'noise', 'color', 'brown-unif', 'amplitude', .05, 'probability', 1, 'probabilitySlope', 0);
noiseSignalBrain = noise_check_class(noiseSignalBrain);

% --- Define Channel-Specific Noise ---
channelNoise = struct('source', lf_get_source_middle(forwardModel, 'region', {'brain.*'}), ...
                      'signal', {{noiseSignalBrain}});

% --- Component Definition with Anatomical Considerations ---
components = {
    % Muscle artifact 
    struct('source', lf_get_source_random(forwardModel, 'region', {'Muscle_OrbicularisOculi'}), ... 
           'signal', {{muscleSignal}})
    
    % Blink artifacts 
    struct('source', [lf_get_source_middle(forwardModel, 'region', {'EyeCornea_left_vertical'}), ...
                      lf_get_source_middle(forwardModel, 'region', {'EyeCornea_right_vertical'})], ...
           'signal', {{blinkSignal}})
    
    % Noise (Global)
    struct('source', lf_get_source_all(forwardModel), ...
           'signal', {{noiseSignal}}) 
    
    % Brain noise (Applied to brain regions)
    struct('source', lf_get_source_random(forwardModel, 'region', {'brain.*'}), ...
           'signal', {{noiseSignalBrain}})
    
    % P3a (More focused source)
    struct('source', [lf_get_source_middle(forwardModel, 'region', {'Brain_Left_Insular_Cortex'}), ...
                      lf_get_source_middle(forwardModel, 'region', {'Brain_Right_Insular_Cortex'})], ... 
           'signal', {{p3aSignal}})
    
    % P3b (More focused source)
    struct('source', [lf_get_source_middle(forwardModel, 'region', {'Brain_Left_Insular_Cortex'}), ...
                      lf_get_source_middle(forwardModel, 'region', {'Brain_Right_Insular_Cortex'})], ...
           'signal', {{p3bSignal}})
};

% --- Data Generation and Visualization ---
% Create and validate components 
validatedComponents = [];
for i = 1:length(components)
    validatedComponents = [validatedComponents; utl_check_component(components{i}, forwardModel)];
end

% Generate scalp data
data = generate_scalpdata(validatedComponents, forwardModel, epochs);

% Create EEGLAB dataset
EEG = utl_create_eeglabdataset(data, epochs, forwardModel);

% Analysis: Plot EEG data
pop_eegplot(EEG, 1, 0, 0); 

% --- Helper Function ---
function signal = defineERP(peakLatency, peakWidth, peakAmplitude, probability)
    signal = struct('type', 'erp', ...
                    'peakLatency', peakLatency, ...
                    'peakWidth', peakWidth, ...
                    'peakAmplitude', peakAmplitude, ...
                    'peakLatencyDv', peakLatency * 0.2, ... % 20% deviation
                    'peakWidthDv', peakWidth * 0.2, ...       % 20% deviation
                    'peakAmplitudeDv', peakAmplitude * 0.2, ... % 20% deviation
                    'probability', probability, ...
                    'probabilitySlope', 0);
    signal = utl_check_class(signal, 'type', 'erp');
end
