cd("C:\\Users\\Ben Cheng\\Documents\\GitHub\\AA228_CS238_Final_Project\\Code\\csv_gen")
using CSV
using DataFrames
using Random

display("Begin CSV Generation")

handdrawn_df = DataFrame(CSV.File("handdrawn.csv"))

function stateCol(state)
    return state % dimmax
end

function stateRow(state)
    return Int((state - stateCol(state))/dimmax)
end

#Generate the next state based on selected action.
function nextState(state, action, walllist, actionList, threshold)
    #Actions: Up(0), Left(1), Down(2), Right(3)
    move = action
    if threshold != 1 #threshold = likelihood of performing desired movement
        if rand(Float32, 1)[1] < 1-threshold 
            move = rand(deleteat!(copy(actionList), action+1)) #action+1 because actions are 0:3, but deleteat! indexes 1:4
        end
    end
    
    #print(action)
    #print(",")
    #println(move)

    if move == 0 #Move Up
        next_state = state - dimmax
    elseif move == 1 #Move Down
        next_state = state + dimmax
    elseif move == 2 #Move Left
        next_state = state - 1
    elseif move == 3 #Move Right
        next_state = state + 1
    end
    
    #If moving into hit upper or lower boundary, then no change in state.
    #i.e. In a 10x10 grid (0 index), it's impossbile to move beyond the perimeter (below 0, or above 99)
    if next_state < 0 || next_state > (dimmax^2-1) 
        return state
    end
    
    #If moving into left or right boundary, then no change in state (aka, mathematically causes the nextstate to "wrap over" a row).
    #i.e. In a 10x10 grid, it's impossible to move right from state 79 to 80. And impossible to move left from 70 to 69.
    if move == 2 || move == 3
        if stateRow(state) != stateRow(next_state) 
            return state
        end
    end

    #If moving into a wall, then no change in state.
    if next_state in wallList
        return state
    end
    return next_state
end

#=================MAIN PROGRAM STARTS HERE=================#
#Assumes 2D Square Grid World
dimmax = 10
threshold = 0.9
actionList = collect(0:3)
repeatActionPerState = 200

#Generate List of all Wall Locations
wallList = filter(:state_type => ==("W"), handdrawn_df).states_idx
#Generat List of all locations that aren't walls.
stateList = filter(:state_type => !=("W"), handdrawn_df).states_idx

output_df = DataFrame(s = stateList)
output_df = repeat(output_df, inner = repeatActionPerState*length(actionList))
output_df[!, :a] = repeat(repeat(actionList, inner=repeatActionPerState),length(stateList))
display(output_df)
spList = []
for row in eachrow(output_df)
    append!(spList, nextState(row[:s], row[:a], wallList, actionList, threshold))
end

rewardList = []
for (next_state, state) in zip(spList, output_df.s)
    reward = filter(:states_idx => ==(next_state), handdrawn_df).reward[1]
    #Cool Trick: If Current State = Next State, then we must've hit a wall/boundary. Add Wall Penalty.
    if state == next_state
        reward = reward - 10
    end
    append!(rewardList, reward)
end

output_df[!, :r] = rewardList
output_df[!, :sp] = spList

display(output_df)
CSV.write("custom_dataset.csv", output_df) 