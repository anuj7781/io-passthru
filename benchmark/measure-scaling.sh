dev_char_str=$1;
dev_blk_str=$2;

run()
{
	local pt=$1;
	local od=$2;
	local cs;
	local dev_str;

	i=1;
	core_str='0';
	if [ $pt -eq 1 ]
	then
		dev_str=${dev_char_str};
		cs=' -O0 -u1';
		of='pt';
	else
		dev_str=${dev_blk_str};
		cs=' -O1';
		of='blk';
	fi

	printf "Scaling Test: ${dev_str} on cpu ${core_str}\n"

	if [ $pt -eq 1 ]
	then
		printf "\nPassthru with depth 1\n" >>  ${od}/$of
	else
		printf "\nBlock with depth 1\n" >>  ${od}/$of
	fi
	taskset -c $core_str t/io_uring -r4 -b512 -d1 -c1 -s1 -p1 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of

	if [ $pt -eq 1 ]
	then
		printf "\nPassthru with depth 8\n" >>  ${od}/$of
	else
		printf "\nBlock with depth 8\n" >>  ${od}/$of
	fi
	taskset -c $core_str t/io_uring -r4 -b512 -d8 -c2 -s2 -p1 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of

	if [ $pt -eq 1 ]
	then
		printf "\nPassthru with depth 16\n" >>  ${od}/$of
	else
		printf "\nBlock with depth 16\n" >>  ${od}/$of
	fi
	taskset -c $core_str t/io_uring -r4 -b512 -d16 -c4 -s4 -p1 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of

	if [ $pt -eq 1 ]
	then
		printf "\nPassthru with depth 32\n" >>  ${od}/$of
	else
		printf "\nBlock with depth 32\n" >>  ${od}/$of
	fi
	taskset -c $core_str t/io_uring -r4 -b512 -d32 -c8 -s8 -p1 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of

	if [ $pt -eq 1 ]
	then
		printf "\nPassthru with depth 64\n" >>  ${od}/$of
	else
		printf "\nBlock with depth 64\n" >>  ${od}/$of
	fi
	taskset -c $core_str t/io_uring -r4 -b512 -d64 -c16 -s16 -p1 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of

	if [ $pt -eq 1 ]
	then
		printf "\nPassthru with depth 128\n" >>  ${od}/$of
	else
		printf "\nBlock with depth 128\n" >>  ${od}/$of
	fi
	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p1 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of
}

outdir=out-$(date +"%d-%m-%Y-%H-%M-%S")
mkdir $outdir
echo "output will be inside the dir $outdir"

#passthru test
run 1 $outdir

#block test
run 0 $outdir
